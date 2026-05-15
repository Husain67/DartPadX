import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String rawResponse;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.rawResponse = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? rawResponse,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;
  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clear() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider).files;
    final activeId = ref.read(fileProvider).activeFileId;
    final activeFile = fileState.firstWhere((f) => f.id == activeId);

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.useDefaultOneCompiler
        ? compilerState.presets.firstWhere((p) => p.name == 'OneCompiler')
        : compilerState.presets.firstWhere((p) => p.id == compilerState.activePresetId);

    await _runWithPreset(preset, activeFile.content);
  }

  Future<void> testConnection(CompilerPreset preset) async {
    await _runWithPreset(preset, "void main() { print('Hello from custom API'); }");
  }

  Future<void> _runWithPreset(CompilerPreset preset, String code) async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '', rawResponse: '');

    try {
      final stdin = ref.read(stdinProvider);

      var url = Uri.parse(preset.url);
      if (preset.queryParams.isNotEmpty) {
          final queryParams = Map<String, dynamic>.from(url.queryParameters);
          queryParams.addAll(preset.queryParams);
          if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
              queryParams[preset.authKey] = preset.authValue;
          }
          url = url.replace(queryParameters: queryParams);
      } else if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
          final queryParams = Map<String, dynamic>.from(url.queryParameters);
          queryParams[preset.authKey] = preset.authValue;
          url = url.replace(queryParameters: queryParams);
      }

      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
        headers[preset.authKey] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final basicAuth = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $basicAuth';
      }

      String requestBody = preset.bodyTemplate;
      if (requestBody.isNotEmpty) {
        String safeCode = jsonEncode(code);
        safeCode = safeCode.substring(1, safeCode.length - 1);
        String safeStdin = jsonEncode(stdin);
        safeStdin = safeStdin.substring(1, safeStdin.length - 1);

        requestBody = requestBody.replaceAll('{code}', safeCode);
        requestBody = requestBody.replaceAll('{stdin}', safeStdin);
      }

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(url, headers: headers, body: requestBody.isEmpty ? null : requestBody);
      } else {
        response = await http.get(url, headers: headers);
      }

      state = state.copyWith(rawResponse: response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String getNestedValue(Map<String, dynamic> map, String path) {
          if (path.isEmpty) return '';
          final keys = path.split('.');
          dynamic current = map;
          for (var key in keys) {
            if (current is Map<String, dynamic> && current.containsKey(key)) {
              current = current[key];
            } else {
              return '';
            }
          }
          return current?.toString() ?? '';
        }

        final out = getNestedValue(data, preset.stdoutPath);
        final err = getNestedValue(data, preset.stderrPath);
        final exception = getNestedValue(data, preset.errorPath);
        final time = getNestedValue(data, preset.executionTimePath);
        final mem = getNestedValue(data, preset.memoryPath);

        state = state.copyWith(
          isRunning: false,
          stdout: out,
          stderr: [err, exception].where((e) => e.isNotEmpty).join('\n'),
          executionTime: time,
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
        stderr: 'Execution Error: $e',
      );
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
