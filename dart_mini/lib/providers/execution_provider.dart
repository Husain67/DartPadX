import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

final stdinProvider = StateProvider<String>((ref) => '');

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code) async {
    final _ = ref.read(settingsProvider);
    final stdin = ref.read(stdinProvider);
    final preset = ref.read(settingsProvider.notifier).getActivePreset();

    if (preset == null || preset.url.isEmpty) {
      state = state.copyWith(error: 'Invalid or missing Custom Compiler preset URL.');
      return;
    }

    state = state.copyWith(
      isExecuting: true,
      stdout: '',
      stderr: '',
      error: '',
      executionTime: '',
      memory: '',
    );

    try {
      final headers = Map<String, String>.from(preset.headers);

      // Handle Auth
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = preset.authValue;
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      }

      // Handle Query Params
      String finalUrl = preset.url;
      if (preset.queryParams.isNotEmpty) {
        final uri = Uri.parse(finalUrl);
        finalUrl = uri.replace(queryParameters: preset.queryParams).toString();
      } else if (preset.authType == 'Query Param' && preset.authValue.isNotEmpty) {
         final uri = Uri.parse(finalUrl);
         finalUrl = uri.replace(queryParameters: {'api_key': preset.authValue}).toString();
      }

      // Prepare Body
      String body = preset.bodyTemplate;

      // We must safely encode the dart code to JSON to handle newlines, quotes, etc.
      // We encode, then strip the starting and ending quotes of the json string
      String safeCode = jsonEncode(code);
      safeCode = safeCode.substring(1, safeCode.length - 1);

      String safeStdin = jsonEncode(stdin);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1);

      body = body.replaceAll('{code}', safeCode);
      body = body.replaceAll('{stdin}', safeStdin);

      http.Response response;
      final uri = Uri.parse(finalUrl);

      if (preset.method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.method}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        state = state.copyWith(
          isExecuting: false,
          stdout: _extractPath(data, preset.stdoutPath),
          stderr: _extractPath(data, preset.stderrPath),
          error: _extractPath(data, preset.errorPath),
          executionTime: _extractPath(data, preset.executionTimePath),
          memory: _extractPath(data, preset.memoryPath),
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          error: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
      );
    }
  }

  String _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';

    final keys = path.split('.');
    dynamic current = data;

    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }

    return current?.toString() ?? '';
  }
}
