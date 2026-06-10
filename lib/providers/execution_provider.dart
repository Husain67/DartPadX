import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_provider.dart';

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
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code) async {
    final compilerState = _ref.read(compilerProvider);
    final stdin = _ref.read(stdinProvider);

    CompilerPreset? preset;

    if (compilerState.useDefaultOneCompiler) {
        preset = compilerState.presets.firstWhere(
            (p) => p.id == 'default_onecompiler',
            orElse: () => throw Exception('Default OneCompiler preset not found!'),
        );
    } else {
        preset = compilerState.activePreset;
    }

    if (preset == null) {
      state = state.copyWith(error: 'No compiler preset selected.');
      return;
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    try {
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      final headers = Map<String, String>.from(preset.headers);

      // Handle Auth Type
      if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
         // Usually handled by UI injecting it into headers, but just in case
      }

      // Safe JSON embedding
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1); // remove surrounding quotes

      String encodedStdin = jsonEncode(stdin);
      encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      String body = preset.requestBodyTemplate
          .replaceAll('{code}', encodedCode)
          .replaceAll('{stdin}', encodedStdin)
          .replaceAll('{language}', 'dart');

      http.Response response;

      final startTime = DateTime.now();

      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      final endTime = DateTime.now();
      final defaultExecTime = "${endTime.difference(startTime).inMilliseconds} ms";

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        final stdout = _extractValue(jsonResponse, preset.responseStdoutPath) ?? '';
        final stderr = _extractValue(jsonResponse, preset.responseStderrPath) ?? '';
        final error = _extractValue(jsonResponse, preset.responseErrorPath) ?? '';
        final time = _extractValue(jsonResponse, preset.responseTimePath) ?? defaultExecTime;
        final mem = _extractValue(jsonResponse, preset.responseMemoryPath) ?? '';

        state = state.copyWith(
          isExecuting: false,
          stdout: stdout.toString(),
          stderr: stderr.toString(),
          error: error.toString(),
          executionTime: time.toString(),
          memory: mem.toString(),
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          error: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(isExecuting: false, error: 'Execution Exception: $e');
    }
  }

  dynamic _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
