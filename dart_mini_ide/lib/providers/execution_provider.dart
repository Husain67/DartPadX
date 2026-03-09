import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_provider.dart';

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    required this.isExecuting,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
  });

  factory ExecutionState.initial() {
    return ExecutionState(
      isExecuting: false,
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );
  }

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
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState.initial());

  void clearOutput() {
    state = ExecutionState.initial();
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(
      isExecuting: true,
      stdout: 'Compiling & Executing...\n',
      stderr: '',
      executionTime: '',
      memory: '',
    );

    try {
      final activePreset = ref.read(compilerProvider.notifier).activePreset;

      if (activePreset == null || activePreset.endpointUrl.isEmpty) {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'Error: No active compiler preset selected or endpoint URL is empty.',
        );
        return;
      }

      await _runCustomPreset(code, stdin, activePreset);
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Network or Execution Error: \$e',
      );
    }
  }

  Future<void> _runCustomPreset(String code, String stdin, CompilerPreset preset) async {
    final url = Uri.parse(preset.endpointUrl);

    // Prepare Request Body
    String requestBody = preset.requestBodyTemplate;

    // Safely encode code and stdin to JSON strings so they don't break JSON structure
    // But remove the surrounding quotes because they might be already present in the template
    String encodedCode = jsonEncode(code);
    encodedCode = encodedCode.substring(1, encodedCode.length - 1); // remove ""

    String encodedStdin = jsonEncode(stdin);
    encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

    requestBody = requestBody.replaceAll('{code}', '"\$encodedCode"');
    requestBody = requestBody.replaceAll('"{code}"', '"\$encodedCode"'); // just in case
    requestBody = requestBody.replaceAll('{stdin}', encodedStdin);
    requestBody = requestBody.replaceAll('{language}', 'dart');

    // Build Headers
    Map<String, String> requestHeaders = Map.from(preset.headers);
    if (preset.authType == 'Bearer Token') {
      // Logic for adding Bearer token if we had a field for it,
      // Assuming it's already manually added to headers for now based on UI
    }

    try {
      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(url, headers: requestHeaders, body: requestBody);
      } else if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(url, headers: requestHeaders);
      } else {
        response = await http.post(url, headers: requestHeaders, body: requestBody);
      }

      _parseResponse(response.body, preset);
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'HTTP Request Failed: \$e',
      );
    }
  }

  void _parseResponse(String responseBody, CompilerPreset preset) {
    try {
      final decodedResponse = jsonDecode(responseBody);
      if (decodedResponse is Map<String, dynamic>) {
        String parsedStdout = _extractValueByPath(decodedResponse, preset.stdoutPath) ?? '';
        String parsedStderr = _extractValueByPath(decodedResponse, preset.stderrPath) ?? '';
        String parsedError = _extractValueByPath(decodedResponse, preset.errorPath) ?? '';
        String parsedTime = _extractValueByPath(decodedResponse, preset.executionTimePath) ?? '';
        String parsedMemory = _extractValueByPath(decodedResponse, preset.memoryPath) ?? '';

        String finalStderr = parsedStderr.isNotEmpty ? parsedStderr : parsedError;

        // Fallback for empty mapping
        if (parsedStdout.isEmpty && finalStderr.isEmpty) {
          parsedStdout = 'Raw Response:\n\$responseBody';
        }

        state = state.copyWith(
          isExecuting: false,
          stdout: parsedStdout,
          stderr: finalStderr,
          executionTime: parsedTime,
          memory: parsedMemory,
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          stdout: 'Raw Response:\n\$responseBody',
        );
      }
    } catch (e) {
      // Not JSON
      state = state.copyWith(
        isExecuting: false,
        stdout: responseBody,
        stderr: 'Could not parse response as JSON. Showing raw response.',
      );
    }
  }

  String? _extractValueByPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
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
