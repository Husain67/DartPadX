import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dartmini_ide/src/features/settings/providers/compiler_provider.dart';
import 'package:dartmini_ide/src/features/settings/domain/compiler_preset.dart';

class ExecutionState {
  final bool isRunning;
  final String output;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.output = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? output,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      output: output ?? this.output,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> runCode(String code) async {
    state = state.copyWith(isRunning: true, output: '', error: '', executionTime: '', memory: '');
    final stdinStr = ref.read(stdinProvider);
    final compilerState = ref.read(compilerProvider);

    try {
      if (compilerState.useDefaultOneCompiler) {
        await _runDefaultOneCompiler(code, stdinStr);
      } else {
        await _runCustomPreset(code, stdinStr, compilerState.activePreset);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, error: 'Execution Failed: $e');
    }
  }

  Future<void> _runDefaultOneCompiler(String code, String stdinStr) async {
    const apiKey = String.fromEnvironment('API_KEY');

    final response = await http.post(
      Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdinStr,
        "files": [
          {
            "name": "main.dart",
            "content": code
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        output: json['stdout']?.toString() ?? '',
        error: (json['stderr']?.toString() ?? '') + (json['exception']?.toString() ?? ''),
        executionTime: json['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(isRunning: false, error: 'HTTP Error: ${response.statusCode}\n${response.body}');
    }
  }

  Future<void> _runCustomPreset(String code, String stdinStr, CompilerPreset? preset) async {
    if (preset == null) throw Exception("No preset selected");

    String body = preset.requestBodyTemplate
        .replaceAll('{code}', code.replaceAll('\n', '\\n').replaceAll('"', '\\"'))
        .replaceAll('{stdin}', stdinStr.replaceAll('\n', '\\n').replaceAll('"', '\\"'));

    Map<String, String> resolvedHeaders = Map.from(preset.headers);
    if (preset.authType == 'Bearer Token') {
       // Typically you'd prompt or resolve this, for now just use what's in headers
    } else if (preset.authType == 'API-Key Header') {
       // same
    }

    Uri uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    http.Response response;
    if (preset.httpMethod == 'POST') {
      response = await http.post(uri, headers: resolvedHeaders, body: body.isEmpty ? null : body);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(uri, headers: resolvedHeaders, body: body.isEmpty ? null : body);
    } else {
      response = await http.get(uri, headers: resolvedHeaders);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);

      String getValue(Map<String, dynamic> data, String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = data;
        for (final part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      state = state.copyWith(
        isRunning: false,
        output: getValue(json, preset.stdoutPath),
        error: getValue(json, preset.stderrPath) + getValue(json, preset.errorPath),
        executionTime: getValue(json, preset.executionTimePath),
        memory: getValue(json, preset.memoryPath),
      );
    } else {
      state = state.copyWith(isRunning: false, error: 'HTTP Error: ${response.statusCode}\n${response.body}');
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
