import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';
import 'file_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

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
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.isEmpty) {
      state = state.copyWith(stderr: 'Error: No code to execute.', isRunning: false);
      return;
    }

    final code = activeFile.content;
    final preset = ref.read(settingsProvider.notifier).activePreset;

    state = state.copyWith(
      isRunning: true,
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );

    try {
      final startTime = DateTime.now();

      // Process Body Template
      String processedBody = preset.requestBodyTemplate;
      String jsonEncodedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');

      processedBody = processedBody.replaceAll('{code}', '"\$jsonEncodedCode"');
      processedBody = processedBody.replaceAll('{language}', '"dart"');
      // basic stdin support for custom templates if needed
      processedBody = processedBody.replaceAll('{stdin}', '');

      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: preset.headers, body: processedBody);
      } else if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: preset.headers);
      } else {
         state = state.copyWith(stderr: 'Unsupported HTTP Method: \${preset.httpMethod}', isRunning: false);
         return;
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String parsePath(Map<String, dynamic> json, String path) {
          if (path.isEmpty) return '';
          try {
            List<String> keys = path.split('.');
            dynamic current = json;
            for (String key in keys) {
              if (current is Map && current.containsKey(key)) {
                current = current[key];
              } else {
                return '';
              }
            }
            return current?.toString() ?? '';
          } catch (e) {
             return '';
          }
        }

        String stdoutResult = parsePath(data, preset.stdoutPath);
        String stderrResult = parsePath(data, preset.stderrPath);
        String errorResult = parsePath(data, preset.errorPath);
        String timeResult = parsePath(data, preset.timePath);
        String memoryResult = parsePath(data, preset.memoryPath);

        if (timeResult.isEmpty) timeResult = '\${duration}ms';

        // Custom handling for Replit/OneCompiler empty returns sometimes
        if (stdoutResult.isEmpty && stderrResult.isEmpty && errorResult.isEmpty) {
          stdoutResult = 'Execution completed. (No output or mapping failed)';
        }

        state = state.copyWith(
          isRunning: false,
          stdout: stdoutResult,
          stderr: '\$stderrResult \$errorResult'.trim(),
          executionTime: timeResult,
          memory: memoryResult,
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

  Future<void> testConnection(CompilerPreset preset) async {
      state = state.copyWith(isRunning: true, stdout: '', stderr: 'Testing connection...');

      try {
        String testCode = "void main() { print('Hello from custom API'); }";
        String processedBody = preset.requestBodyTemplate;
        String jsonEncodedCode = jsonEncode(testCode).replaceAll(RegExp(r'^"|"$'), '');

        processedBody = processedBody.replaceAll('{code}', '"\$jsonEncodedCode"');
        processedBody = processedBody.replaceAll('{language}', '"dart"');
        processedBody = processedBody.replaceAll('{stdin}', '');

        final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

        http.Response response;
        if (preset.httpMethod.toUpperCase() == 'POST') {
          response = await http.post(uri, headers: preset.headers, body: processedBody);
        } else {
          response = await http.get(uri, headers: preset.headers);
        }

        final responseBody = response.body;

        String parsedOutput = '';
        if (response.statusCode >= 200 && response.statusCode < 300) {
            final data = jsonDecode(responseBody);
            String parsePath(Map<String, dynamic> json, String path) {
              if (path.isEmpty) return '';
              try {
                List<String> keys = path.split('.');
                dynamic current = json;
                for (String key in keys) {
                  if (current is Map && current.containsKey(key)) {
                    current = current[key];
                  } else {
                    return '';
                  }
                }
                return current?.toString() ?? '';
              } catch (e) { return ''; }
            }
            parsedOutput = parsePath(data, preset.stdoutPath);
        }

        state = state.copyWith(
          isRunning: false,
          stdout: "RAW RESPONSE:\\n\$responseBody\\n\\nPARSED OUTPUT:\\n\$parsedOutput",
          stderr: response.statusCode >= 300 ? 'HTTP Error \${response.statusCode}' : '',
        );

      } catch (e) {
          state = state.copyWith(isRunning: false, stderr: 'Test Error: \$e');
      }
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '');
  }
}
