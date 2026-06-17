import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final settingsState = ref.watch(settingsProvider);
  return ExecutionNotifier(settingsState);
});

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final SettingsState _settings;

  ExecutionNotifier(this._settings) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isLoading: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final preset = _settings.activePreset;
    String url = preset.url;

    // Auth & Headers
    Map<String, String> headers = Map.from(preset.headers);
    if (preset.authType == 'API-Key Header') {
      if (preset.id == 'preset_onecompiler_default') {
        final key = _settings.oneCompilerApiKey;
        if (key.isEmpty) {
          state = state.copyWith(isLoading: false, stderr: 'OneCompiler API Key is missing. Please set it in Settings.');
          return;
        }
        headers['X-RapidAPI-Key'] = key;
      }
    } else if (preset.authType == 'Bearer Token') {
      // Implement Bearer handling if needed
    }

    // Body
    String bodyStr = preset.bodyTemplate;
    bodyStr = bodyStr.replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1));
    bodyStr = bodyStr.replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1));

    try {
      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(Uri.parse(url), headers: headers, body: bodyStr);
      } else {
        response = await http.get(Uri.parse(url), headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String extractedStdout = _extractValue(data, preset.stdoutPath) ?? '';
        String extractedStderr = _extractValue(data, preset.stderrPath) ?? '';
        String extractedError = _extractValue(data, preset.errorPath) ?? '';
        String extractedTime = _extractValue(data, preset.executionTimePath) ?? '';
        String extractedMemory = _extractValue(data, preset.memoryPath) ?? '';

        String finalStderr = extractedStderr.isNotEmpty ? extractedStderr : extractedError;

        state = state.copyWith(
          isLoading: false,
          stdout: extractedStdout,
          stderr: finalStderr,
          executionTime: extractedTime,
          memory: extractedMemory,
        );
      } else {
        state = state.copyWith(isLoading: false, stderr: 'HTTP Error \${response.statusCode}: \${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, stderr: 'Execution Failed: \$e');
    }
  }

  String? _extractValue(dynamic data, String path) {
    if (path.isEmpty) return null;
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
