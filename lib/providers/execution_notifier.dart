import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../models/response_mapping.dart';

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

  Future<void> executeCode({
    required String code,
    required String stdinStr,
    required CompilerPreset preset,
  }) async {
    if (code.trim().isEmpty) return;
    if (preset.endpointUrl.isEmpty) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Error: Compiler endpoint URL is empty. Please configure the preset.',
      );
      return;
    }

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      var uri = Uri.parse(preset.endpointUrl);

      // Handle query parameters
      if (preset.queryParams.isNotEmpty) {
        final queryParams = Map<String, dynamic>.from(uri.queryParameters);
        queryParams.addAll(preset.queryParams);
        uri = uri.replace(queryParameters: queryParams);
      }

      // Prepare headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
        // Assume already formatted or needs formatting in UI
      }

      // Escape code and stdin for JSON stringification
      String safeCode = jsonEncode(code);
      safeCode = safeCode.substring(1, safeCode.length - 1);

      String safeStdin = jsonEncode(stdinStr);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1);

      String bodyStr = preset.requestBodyTemplate
          .replaceAll('{code}', safeCode)
          .replaceAll('{stdin}', safeStdin)
          .replaceAll('{language}', 'dart');

      http.Response response;

      final startTime = DateTime.now();

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr); // Fallback
      }

      final endTime = DateTime.now();
      final defaultExecTime = '${endTime.difference(startTime).inMilliseconds} ms';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        final stdout = _extractValue(decoded, preset.responseMapping.stdoutPath) ?? '';
        final stderrStr = _extractValue(decoded, preset.responseMapping.stderrPath) ?? '';
        final errorStr = _extractValue(decoded, preset.responseMapping.errorPath) ?? '';

        final combinedStderr = [stderrStr, errorStr].where((s) => s.isNotEmpty).join('\n');

        final execTime = _extractValue(decoded, preset.responseMapping.timePath) ?? defaultExecTime;
        final mem = _extractValue(decoded, preset.responseMapping.memoryPath) ?? 'N/A';

        state = state.copyWith(
          isRunning: false,
          stdout: stdout.toString(),
          stderr: combinedStderr.toString(),
          executionTime: execTime.toString(),
          memory: mem.toString(),
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}\n${response.body}',
          executionTime: defaultExecTime,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Exception occurred: $e',
      );
    }
  }

  String? _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;

    final keys = path.split('.');
    dynamic current = data;

    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }

  // Expose extract value logic for preset editor test connection
  String? extractValue(dynamic data, String path) {
    return _extractValue(data, path);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
