import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';
import 'preset_provider.dart';
import 'file_provider.dart';

final stdinProvider = StateProvider<String>((ref) => '');

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

// immutable fields shouldn't be set directly in clear() method;
// state logic handles clearing state by re-instantiating instead.
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final code = activeFile.content;
    final stdin = ref.read(stdinProvider);
    final useDefault = ref.read(settingsProvider).useDefaultOneCompiler;

    CompilerPreset preset;
    if (useDefault) {
      final defaultPresets = ref.read(presetProvider.notifier).state.presets;
      preset = defaultPresets.firstWhere((p) => p.name == 'OneCompiler', orElse: () => defaultPresets.first);
    } else {
      final activePreset = ref.read(presetProvider).activePreset;
      if (activePreset == null) {
        state = state.copyWith(error: 'No active preset selected.');
        return;
      }
      preset = activePreset;
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    try {
      final requestUri = Uri.parse(preset.url).replace(
        queryParameters: preset.queryParams.isNotEmpty
          ? Map.fromEntries(preset.queryParams)
          : null
      );

      final headers = <String, String>{};
      for (var entry in preset.headers) {
        headers[entry.key] = entry.value;
      }

      if (preset.authType == 'API-Key Header' && preset.authValue != null) {
        headers['Authorization'] = preset.authValue!;
      } else if (preset.authType == 'Bearer Token' && preset.authValue != null) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue!))}';
      }

      String bodyStr = preset.bodyTemplate
          .replaceAll('"{code}"', jsonEncode(code))
          .replaceAll('"{stdin}"', jsonEncode(stdin))
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{stdin}', jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(requestUri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(requestUri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(requestUri, headers: headers, body: bodyStr);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isExecuting: false,
          stdout: _extractValue(data, preset.stdoutPath),
          stderr: _extractValue(data, preset.stderrPath),
          error: _extractValue(data, preset.errorPath),
          executionTime: _extractValue(data, preset.executionTimePath),
          memory: _extractValue(data, preset.memoryPath),
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(isExecuting: false, error: e.toString());
    }
  }

  String _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}
