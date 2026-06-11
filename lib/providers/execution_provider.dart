import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String stdin;
  final bool isOutputVisible;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.stdin = '',
    this.isOutputVisible = false,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? stdin,
    bool? isOutputVisible,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      stdin: stdin ?? this.stdin,
      isOutputVisible: isOutputVisible ?? this.isOutputVisible,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void setStdin(String input) {
    state = state.copyWith(stdin: input);
  }

  void setOutputVisible(bool visible) {
    state = state.copyWith(isOutputVisible: visible);
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '');
  }

  Future<void> executeCode(String code) async {
    state = state.copyWith(isRunning: true, isOutputVisible: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.activePreset;

    if (preset == null) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'No compiler preset selected.',
      );
      return;
    }

    try {
      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      // Prepare body
      // We must escape JSON inside the template, but simplify by using replacement safely
      String bodyString = preset.requestBodyTemplate;

      // Safe JSON escaping for code and stdin
      final encodedCode = jsonEncode(code);
      final rawCode = encodedCode.substring(1, encodedCode.length - 1);

      final encodedStdin = jsonEncode(state.stdin);
      final rawStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      bodyString = bodyString.replaceAll('{code}', rawCode);
      bodyString = bodyString.replaceAll('{stdin}', rawStdin);

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(
          uri,
          headers: preset.headers,
          body: bodyString,
        );
      } else {
        response = await http.get(uri, headers: preset.headers);
      }

      _parseResponse(response.body, preset);

    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: $e',
      );
    }
  }

  void _parseResponse(String responseBody, preset) {
    try {
      final decoded = jsonDecode(responseBody);

      String extOut = _extractByPath(decoded, preset.stdoutPath) ?? '';
      String extErr = _extractByPath(decoded, preset.stderrPath) ?? '';
      String extError = _extractByPath(decoded, preset.errorPath) ?? '';
      String extTime = _extractByPath(decoded, preset.executionTimePath) ?? '';
      String extMem = _extractByPath(decoded, preset.memoryPath) ?? '';

      // Fallback logic
      if (extErr.isEmpty && extError.isNotEmpty) {
        extErr = extError;
      }

      state = state.copyWith(
        isRunning: false,
        stdout: extOut,
        stderr: extErr,
        executionTime: extTime.toString(),
        memory: extMem.toString(),
      );

    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Failed to parse response: $e\nRaw Response:\n$responseBody',
      );
    }
  }

  dynamic _extractByPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
