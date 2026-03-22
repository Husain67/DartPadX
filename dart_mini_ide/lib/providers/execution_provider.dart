import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../utils/json_mapper.dart';
import 'compiler_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    final activePresetId = ref.read(activeCompilerIdProvider);
    final presets = ref.read(compilerProvider);
    CompilerPreset? preset;

    try {
      if (activePresetId != null) {
        preset = presets.firstWhere((p) => p.id == activePresetId);
      } else if (presets.isNotEmpty) {
        preset = presets.first;
      }
    } catch (_) {
      preset = null;
    }

    if (preset == null) {
      state = state.copyWith(
        isRunning: false,
        error: 'No valid compiler preset selected. Please check Settings.',
      );
      return;
    }

    try {
      // 1. Prepare URL & Query Params
      var uri = Uri.parse(preset.url);
      if (preset.queryParams.isNotEmpty) {
        final Map<String, dynamic> qParams = Map.from(uri.queryParameters);
        for (var q in preset.queryParams) {
          if (q['key']!.isNotEmpty) {
             qParams[q['key']!] = q['value'];
          }
        }
        uri = uri.replace(queryParameters: qParams);
      }

      // 2. Prepare Headers
      final Map<String, String> requestHeaders = {};
      for (var h in preset.headers) {
         if (h['key']!.isNotEmpty) {
             requestHeaders[h['key']!] = h['value']!;
         }
      }

      if (preset.authType == 'Bearer' && preset.headers.any((h) => h['key'] == 'Authorization')) {
        // Assume already set via headers if configured, or can add special logic
      }

      // 3. Prepare Body
      String requestBody = '';
      if (preset.method == 'POST' || preset.method == 'PUT') {
        final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
        final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

        requestBody = preset.bodyTemplate
            .replaceAll('{code}', '"$safeCode"')
            .replaceAll('{stdin}', safeStdin)
            .replaceAll('{language}', 'dart');
      }

      // 4. Send HTTP Request
      http.Response response;
      if (preset.method == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: requestBody);
      } else {
        response = await http.post(uri, headers: requestHeaders, body: requestBody);
      }

      // 5. Parse Response
      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Map paths
        final rawStdout = preset.stdoutPath.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, preset.stdoutPath) : '';
        final rawStderr = preset.stderrPath.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, preset.stderrPath) : '';
        final rawError = preset.errorPath.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, preset.errorPath) : '';
        final rawExecTime = preset.executionTimePath.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, preset.executionTimePath) : '';
        final rawMemory = preset.memoryPath.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, preset.memoryPath) : '';

        state = state.copyWith(
          isRunning: false,
          stdout: rawStdout?.toString() ?? '',
          stderr: rawStderr?.toString() ?? '',
          error: rawError?.toString() ?? '',
          executionTime: rawExecTime?.toString() ?? '',
          memory: rawMemory?.toString() ?? '',
        );
      } else {
        // API Error
        state = state.copyWith(
          isRunning: false,
          error: 'API Error (${response.statusCode}):\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: 'Execution failed: $e',
      );
    }
  }
}
