import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/compiler_preset.dart';
import 'preset_provider.dart';
import 'file_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  Future<void> executeCode() async {
    final fileState = _ref.read(fileProvider);
    final presetState = _ref.read(presetProvider);

    final code = fileState.currentFile?.content ?? '';
    if (code.isEmpty) return;

    state = ExecutionState(isExecuting: true);

    try {
      if (presetState.useDefaultOneCompiler) {
        await _executeDefaultOneCompiler(code);
      } else {
        final preset = presetState.selectedPreset;
        if (preset != null) {
          await _executeCustomPreset(code, preset);
        } else {
          state = state.copyWith(isExecuting: false, error: 'No custom preset selected.');
        }
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: 'Execution failed: $e',
      );
    }
  }

  Future<void> _executeDefaultOneCompiler(String code) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');

    // Fallback key, usually you'd get this from String.fromEnvironment or config
    final apiKey = const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

    final headers = {
      'x-rapidapi-key': apiKey,
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "language": "dart",
      "stdin": "",
      "files": [
        {
          "name": "main.dart",
          "content": code
        }
      ]
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      state = state.copyWith(
        isExecuting: false,
        stdout: jsonResponse['stdout'] ?? '',
        stderr: jsonResponse['stderr'] ?? '',
        error: jsonResponse['exception'] ?? '',
        executionTime: jsonResponse['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(
        isExecuting: false,
        error: 'API Error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> testCustomPreset(CompilerPreset preset) async {
    state = ExecutionState(isExecuting: true);
    try {
      await _executeCustomPreset("void main() { print('Hello from custom API'); }", preset);
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: 'Execution failed: $e',
      );
    }
  }

  Future<void> _executeCustomPreset(String code, CompilerPreset preset) async {
    final url = Uri.parse(preset.endpointUrl);
    final headers = Map<String, String>.from(preset.headers);

    // Basic formatting for JSON body template
    // Note: A robust system might use a templating engine. This is a simple replacement.
    // We encode code to escape newlines/quotes properly for JSON.
    String safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    String body = preset.requestBodyTemplate
        .replaceAll('{code}', safeCode)
        .replaceAll('{stdin}', '')
        .replaceAll('{language}', 'dart');

    http.Response response;

    if (preset.httpMethod.toUpperCase() == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (preset.httpMethod.toUpperCase() == 'PUT') {
      response = await http.put(url, headers: headers, body: body);
    } else {
      response = await http.post(url, headers: headers, body: body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonResponse = jsonDecode(response.body);

        state = state.copyWith(
          isExecuting: false,
          stdout: _extractJsonPath(jsonResponse, preset.stdoutPath),
          stderr: _extractJsonPath(jsonResponse, preset.stderrPath),
          error: _extractJsonPath(jsonResponse, preset.errorPath),
          executionTime: _extractJsonPath(jsonResponse, preset.executionTimePath),
          memory: _extractJsonPath(jsonResponse, preset.memoryPath),
        );
      } catch (e) {
         state = state.copyWith(
          isExecuting: false,
          error: 'Failed to parse JSON response: $e\nRaw Response: ${response.body}',
        );
      }
    } else {
      state = state.copyWith(
        isExecuting: false,
        error: 'API Error: ${response.statusCode}\n${response.body}',
      );
    }
  }

  String _extractJsonPath(dynamic json, String path) {
    if (path.isEmpty || json == null) return '';

    final parts = path.split('.');
    dynamic current = json;

    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }

    return current?.toString() ?? '';
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
