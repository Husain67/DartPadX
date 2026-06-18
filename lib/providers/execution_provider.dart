import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_provider.dart';
import '../models/compiler_preset.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
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
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin, CompilerPreset preset) async {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      if (preset.endpointUrl.isEmpty) {
        state = state.copyWith(isRunning: false, stderr: 'Endpoint URL is empty.');
        return;
      }

      final uri = Uri.parse(preset.endpointUrl);

      String requestBody = preset.requestBodyTemplate
          .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
          .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
          .replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: preset.headers, body: requestBody);
      } else {
        response = await http.get(uri, headers: preset.headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String extractedStdout = _extractValue(data, preset.stdoutPath);
        String extractedStderr = _extractValue(data, preset.stderrPath);
        String extractedError = _extractValue(data, preset.errorPath);
        String time = _extractValue(data, preset.executionTimePath);
        String mem = _extractValue(data, preset.memoryPath);

        String finalStderr = extractedStderr;
        if (extractedError.isNotEmpty && extractedError != 'null') {
            finalStderr = finalStderr.isNotEmpty ? "$finalStderr\n$extractedError" : extractedError;
        }

        state = state.copyWith(
          isRunning: false,
          stdout: extractedStdout,
          stderr: finalStderr,
          executionTime: time,
          memory: mem,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Exception:\n$e',
      );
    }
  }

  String _extractValue(Map<String, dynamic> data, String path) {
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
