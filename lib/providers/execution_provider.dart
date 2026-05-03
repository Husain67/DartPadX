import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final String rawResponse;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.rawResponse = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    String? rawResponse,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin, CompilerPreset preset) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', rawResponse: '');

    try {
      final headers = Map<String, String>.from(preset.headers);
      String url = preset.endpointUrl;

      // Handle Auth
      if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
        headers[preset.authKey] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      } else if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
        final uri = Uri.parse(url);
        final newParams = Map<String, String>.from(uri.queryParameters);
        newParams[preset.authKey] = preset.authValue;
        url = uri.replace(queryParameters: newParams).toString();
      }

      // Add Custom Query Params
      if (preset.queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        final newParams = Map<String, String>.from(uri.queryParameters)..addAll(preset.queryParams);
        url = uri.replace(queryParameters: newParams).toString();
      }

      // Prepare Body
      String body = preset.bodyTemplate;
      // Use raw string or careful replacement to avoid issues
      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final escapedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

      body = body.replaceAll('{code}', escapedCode);
      body = body.replaceAll('{stdin}', escapedStdin);
      body = body.replaceAll('{language}', 'dart');

      final uri = Uri.parse(url);
      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        // Default POST
        response = await http.post(uri, headers: headers, body: body);
      }

      final respBody = response.body;
      state = state.copyWith(rawResponse: respBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(respBody);
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
          error: 'HTTP ${response.statusCode}: $respBody',
        );
      }
    } catch (e) {
      state = state.copyWith(isExecuting: false, error: e.toString());
    }
  }

  String _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
