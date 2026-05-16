import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'preset_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final _ = ref.watch(presetProvider);
  return ExecutionNotifier(ref.read(presetProvider.notifier).activePreset);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    required this.isRunning,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final _preset;

  ExecutionNotifier(this._preset)
      : super(ExecutionState(
          isRunning: false,
          stdout: '',
          stderr: '',
          executionTime: '',
          memory: '',
        ));


  ExecutionState get currentState => state;

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '');
  }

  Future<void> executeCode(String code, String stdin) async {
    if (_preset == null) {
      state = state.copyWith(stderr: 'No active compiler preset selected.');
      return;
    }

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final startTime = DateTime.now();

    try {
      final headers = Map<String, String>.from(_preset.headers);

      // Handle Auth
      if (_preset.authType == 'API-Key Header' && _preset.authValue.isNotEmpty) {
        // Assume key name needs to be dynamic or use X-RapidAPI-Key as default if not in headers
        // OneCompiler default has it in headers already, this is a fallback for custom
      } else if (_preset.authType == 'Bearer Token' && _preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${_preset.authValue}';
      } else if (_preset.authType == 'Basic Auth' && _preset.authValue.isNotEmpty) {
        final encoded = base64Encode(utf8.encode(_preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      }

      // Handle Body Template
      // Clean code and stdin for JSON insertion (escape quotes, newlines)
      // For simple replacement, we JSON encode and strip the surrounding quotes
      final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

      String bodyStr = _preset.bodyTemplate;

      bodyStr = bodyStr.replaceAll(RegExp(r'\{code\}'), safeCode.replaceAll(r'$', r'\$'));
      bodyStr = bodyStr.replaceAll(RegExp(r'\{stdin\}'), safeStdin.replaceAll(r'$', r'\$'));
      bodyStr = bodyStr.replaceAll(RegExp(r'\{language\}'), 'dart');

      // Use standard formatting or safer string replacement
      // Instead of chaining, which can replace already inserted content if it matches a template variable
      bodyStr = bodyStr.replaceAll('{code}', safeCode);
      bodyStr = bodyStr.replaceAll('{stdin}', safeStdin);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');

      // Handle Query Params
      final uri = Uri.parse(_preset.endpointUrl).replace(
        queryParameters: _preset.queryParams.isEmpty ? null : _preset.queryParams,
      );

      http.Response response;
      if (_preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (_preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        // Default POST
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      final endTime = DateTime.now();
      final defaultTime = '${endTime.difference(startTime).inMilliseconds} ms';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final respJson = jsonDecode(response.body);

        String parsedStdout = _getValueFromPath(respJson, _preset.stdoutPath) ?? '';
        String parsedStderr = _getValueFromPath(respJson, _preset.stderrPath) ?? '';
        String parsedError = _getValueFromPath(respJson, _preset.errorPath) ?? '';
        String parsedTime = _getValueFromPath(respJson, _preset.executionTimePath)?.toString() ?? defaultTime;
        String parsedMemory = _getValueFromPath(respJson, _preset.memoryPath)?.toString() ?? '';

        if (parsedStderr.isEmpty && parsedError.isNotEmpty) {
          parsedStderr = parsedError;
        }

        state = state.copyWith(
          isRunning: false,
          stdout: parsedStdout.isEmpty && parsedStderr.isEmpty ? 'Process exited with no output.' : parsedStdout,
          stderr: parsedStderr,
          executionTime: parsedTime,
          memory: parsedMemory,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          executionTime: defaultTime,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Exception: $e',
      );
    }
  }

  dynamic _getValueFromPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
