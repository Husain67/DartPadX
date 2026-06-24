import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final compilerState = ref.watch(compilerProvider);
  final activePreset = ref.watch(compilerProvider.notifier).activePreset;
  return ExecutionNotifier(
    useDefault: compilerState.useDefaultCompiler,
    activePreset: activePreset,
  );
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final bool isError;
  final String rawResponse;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.isError = false,
    this.rawResponse = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    bool? isError,
    String? rawResponse,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      isError: isError ?? this.isError,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final bool useDefault;
  final dynamic activePreset; // Using dynamic to avoid direct model import dependency issues if any, but properly typed below

  ExecutionNotifier({required this.useDefault, required this.activePreset}) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', isError: false, rawResponse: '');

    try {
      if (useDefault) {
        await _executeOneCompiler(code, stdin);
      } else {
        if (activePreset == null) {
          throw Exception('No active compiler preset selected.');
        }
        await _executeCustomPreset(code, stdin, activePreset);
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: e.toString(),
        isError: true,
      );
    }
  }

  Future<void> _executeOneCompiler(String code, String stdin) async {
    const defaultKey = String.fromEnvironment('ONECOMPILER_API_KEY');
    final apiKey = defaultKey.isNotEmpty ? defaultKey : 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'; // Fallback per instructions, though environment is preferred

    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      'X-RapidAPI-Key': apiKey,
    };
    final body = jsonEncode({
      'language': 'dart',
      'stdin': stdin,
      'files': [
        {'name': 'main.dart', 'content': code}
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    state = state.copyWith(rawResponse: response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: json['stdout'] ?? '',
        stderr: (json['stderr'] ?? '') + (json['exception'] ?? ''),
        executionTime: json['executionTime']?.toString() ?? '',
        isError: (json['stderr'] != null && json['stderr'].toString().isNotEmpty) || (json['exception'] != null && json['exception'].toString().isNotEmpty),
      );
    } else {
      throw Exception('Failed to execute code: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _executeCustomPreset(String code, String stdin, dynamic preset) async {
    final url = Uri.parse(preset.endpointUrl);

    String bodyStr = preset.requestBodyTemplate;
    bodyStr = bodyStr.replaceAll('{code}', _escapeJsonString(code));
    bodyStr = bodyStr.replaceAll('{stdin}', _escapeJsonString(stdin));
    bodyStr = bodyStr.replaceAll('{language}', 'dart');

    http.Response response;

    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(url, headers: preset.headers, body: bodyStr);
    } else if (preset.httpMethod.toUpperCase() == 'GET') {
      response = await http.get(url, headers: preset.headers);
    } else {
      throw Exception('Unsupported HTTP method: ${preset.httpMethod}');
    }

    state = state.copyWith(rawResponse: response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);

      String stdout = _extractValue(json, preset.responseStdoutPath) ?? '';
      String stderr = _extractValue(json, preset.responseStderrPath) ?? '';
      String error = _extractValue(json, preset.responseErrorPath) ?? '';
      String executionTime = _extractValue(json, preset.responseExecutionTimePath) ?? '';
      String memory = _extractValue(json, preset.responseMemoryPath) ?? '';

      state = state.copyWith(
        isRunning: false,
        stdout: stdout,
        stderr: stderr + (error.isNotEmpty && stderr.isEmpty ? '\n$error' : ''),
        executionTime: executionTime,
        memory: memory,
        isError: stderr.isNotEmpty || error.isNotEmpty,
      );
    } else {
      throw Exception('Failed to execute code: ${response.statusCode} - ${response.body}');
    }
  }

  String _escapeJsonString(String input) {
    return input.replaceAll('\\\\', '\\\\\\\\').replaceAll('"', '\\\\"').replaceAll('\\n', '\\\\n').replaceAll('\\r', '\\\\r').replaceAll('\\t', '\\\\t');
  }

  String? _extractValue(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = json;
    for (var part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
