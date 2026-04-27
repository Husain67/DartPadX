import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, CompilerPreset preset) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', time: '', memory: '');

    try {
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
        headers[preset.authKey] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final basicAuth = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $basicAuth';
      }

      String body = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart')
          .replaceAll('{stdin}', '');

      http.Response response;
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.post(uri, headers: headers, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        String out = _extractFromPath(jsonResponse, preset.stdoutPath) ?? '';
        String err = _extractFromPath(jsonResponse, preset.stderrPath) ?? '';
        String exception = _extractFromPath(jsonResponse, preset.errorPath) ?? '';
        String time = _extractFromPath(jsonResponse, preset.executionTimePath)?.toString() ?? '';
        String mem = _extractFromPath(jsonResponse, preset.memoryPath)?.toString() ?? '';

        if (exception.isNotEmpty && err.isEmpty) {
           err = exception;
        }

        state = state.copyWith(
          isRunning: false,
          stdout: out,
          stderr: err,
          time: time,
          memory: mem,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Exception: $e',
      );
    }
  }

  dynamic _extractFromPath(Map<String, dynamic> json, String path) {
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

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
