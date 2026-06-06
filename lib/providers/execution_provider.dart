import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final headers = <String, String>{};
      for (var h in preset.headers) {
        if (h['key']!.isNotEmpty) {
          headers[h['key']!] = h['value']!;
        }
      }

      String bodyStr = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{stdin}', jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart');

      final uri = Uri.parse(preset.endpoint);

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers); // GET usually doesn't have body but for completeness
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        String getPathValue(String path, Map<String, dynamic> data) {
          if (path.isEmpty) return '';
          List<String> keys = path.split('.');
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

        String stdout = getPathValue(preset.stdoutPath, responseData);
        String stderr = getPathValue(preset.stderrPath, responseData);
        String error = getPathValue(preset.errorPath, responseData);
        String time = getPathValue(preset.executionTimePath, responseData);
        String memory = getPathValue(preset.memoryPath, responseData);

        if (stderr.isEmpty && error.isNotEmpty) {
          stderr = error;
        }

        state = state.copyWith(
          isRunning: false,
          stdout: stdout,
          stderr: stderr,
          executionTime: time,
          memory: memory,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error \${response.statusCode}: \${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: \$e',
      );
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
