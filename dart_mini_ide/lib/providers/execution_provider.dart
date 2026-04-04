import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final compilerState = ref.watch(compilerProvider);
  return ExecutionNotifier(compilerState);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final CompilerState _compilerState;

  ExecutionNotifier(this._compilerState) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    if (code.trim().isEmpty) {
        state = state.copyWith(stderr: 'No code to execute.');
        return;
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      if (_compilerState.useDefaultOneCompiler) {
        await _executeOneCompilerDefault(code, stdin);
      } else {
        final preset = _compilerState.selectedPreset;
        if (preset == null) {
          state = state.copyWith(isExecuting: false, stderr: 'No compiler preset selected.');
          return;
        }
        await _executeCustomPreset(preset, code, stdin);
      }
    } catch (e) {
      state = state.copyWith(isExecuting: false, stderr: 'Execution Error: $e');
    }
  }

  Future<void> _executeOneCompilerDefault(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final headers = {
      'Content-Type': 'application/json',
      'X-RapidAPI-Key': const String.fromEnvironment('RAPID_API_KEY', defaultValue: 'YOUR_API_KEY'),
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
    };

    final body = jsonEncode({
      "language": "dart",
      "stdin": stdin,
      "files": [
        {
          "name": "index.dart",
          "content": code
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final stdout = json['stdout']?.toString() ?? '';
      final exception = json['exception']?.toString() ?? '';
      final stderr = json['stderr']?.toString() ?? '';
      final time = json['executionTime']?.toString() ?? '';

      state = state.copyWith(
        isExecuting: false,
        stdout: stdout,
        stderr: exception.isNotEmpty ? exception : stderr,
        executionTime: time.isNotEmpty ? '$time ms' : '',
      );
    } else {
      state = state.copyWith(isExecuting: false, stderr: 'HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _executeCustomPreset(CompilerPreset preset, String code, String stdin) async {
    var uri = Uri.parse(preset.endpointUrl);

    // Query Params
    if (preset.queryParams.isNotEmpty || preset.authType == 'Query Param') {
      final params = Map<String, String>.from(preset.queryParams);
      if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
        params[preset.authKey] = preset.authValue;
      }
      uri = uri.replace(queryParameters: params);
    }

    // Headers
    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      headers['Authorization'] = 'Basic $encoded';
    }

    // Body
    String bodyStr = preset.requestBodyTemplate;
    // Replace placeholders carefully to avoid breaking JSON string escaping
    final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final escapedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

    bodyStr = bodyStr.replaceAll('{code}', escapedCode);
    bodyStr = bodyStr.replaceAll('{stdin}', escapedStdin);
    bodyStr = bodyStr.replaceAll('{language}', preset.defaultLanguage);

    http.Response response;

    if (preset.httpMethod == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(uri, headers: headers, body: bodyStr);
    } else {
      response = await http.post(uri, headers: headers, body: bodyStr);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body);
        final stdout = _extractValue(json, preset.stdoutPath) ?? '';
        final stderr = _extractValue(json, preset.stderrPath) ?? '';
        final error = _extractValue(json, preset.errorPath) ?? '';
        final time = _extractValue(json, preset.executionTimePath) ?? '';
        final mem = _extractValue(json, preset.memoryPath) ?? '';

        state = state.copyWith(
          isExecuting: false,
          stdout: stdout.toString(),
          stderr: error.toString().isNotEmpty ? error.toString() : stderr.toString(),
          executionTime: time.toString(),
          memory: mem.toString(),
        );
      } catch (e) {
        state = state.copyWith(isExecuting: false, stdout: response.body, stderr: 'Failed to parse JSON response. Raw output shown in stdout.');
      }
    } else {
      state = state.copyWith(isExecuting: false, stderr: 'HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  dynamic _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
