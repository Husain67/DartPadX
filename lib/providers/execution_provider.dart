import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_provider.dart';
import '../models/preset_model.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool isError;
  final bool isRunning;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
    this.isError = false,
    this.isRunning = false,
  });

  ExecutionResult copyWith({
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
    bool? isError,
    bool? isRunning,
  }) {
    return ExecutionResult(
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      isError: isError ?? this.isError,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionResult>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionNotifier extends StateNotifier<ExecutionResult> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionResult());

  void clearOutput() {
    state = ExecutionResult();
  }

  Future<void> runCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', isError: false);

    try {
      final compilerState = ref.read(compilerProvider);

      if (compilerState.useDefaultOneCompiler) {
        await _runWithDefaultOneCompiler(code, stdin);
      } else {
        final presetId = compilerState.activePresetId;
        if (presetId == null) {
          state = state.copyWith(
            isRunning: false,
            isError: true,
            stderr: 'No custom compiler preset selected.',
          );
          return;
        }
        final preset = compilerState.presets.firstWhere(
          (p) => p.id == presetId,
          orElse: () => throw Exception('Preset not found'),
        );
        await _runWithCustomPreset(preset, code, stdin);
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        isError: true,
        stderr: 'Execution Error: $e',
      );
    }
  }

  Future<void> _runWithDefaultOneCompiler(String code, String stdin) async {
    const apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';
    if (apiKey.isEmpty) {
      state = state.copyWith(
        isRunning: false,
        isError: true,
        stderr: 'OneCompiler API key is not configured in the environment. Please use the custom compiler API.',
      );
      return;
    }

    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [
          {
            "name": "main.dart",
            "content": code
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: data['stdout'] ?? '',
        stderr: (data['stderr'] ?? '') + (data['exception'] ?? ''),
        isError: data['status'] != 'success',
        time: '${data['executionTime'] ?? 0} ms',
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        isError: true,
        stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> _runWithCustomPreset(PresetModel preset, String code, String stdin) async {
    if (preset.endpoint.isEmpty) {
      state = state.copyWith(isRunning: false, isError: true, stderr: 'Endpoint URL is empty in preset.');
      return;
    }

    // Prepare body
    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', _escapeJson(code))
        .replaceAll('{stdin}', _escapeJson(stdin))
        .replaceAll('{language}', 'dart');

    var uri = Uri.parse(preset.endpoint);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...preset.queryParams,
      });
    }

    http.Response response;
    final start = DateTime.now();
    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: preset.headers, body: bodyStr.isEmpty ? null : bodyStr);
    } else if (preset.httpMethod.toUpperCase() == 'PUT') {
      response = await http.put(uri, headers: preset.headers, body: bodyStr.isEmpty ? null : bodyStr);
    } else {
      response = await http.get(uri, headers: preset.headers);
    }
    final end = DateTime.now();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isRunning: false,
          stdout: _extractPath(data, preset.stdoutPath) ?? '',
          stderr: (_extractPath(data, preset.stderrPath) ?? '') + '\n' + (_extractPath(data, preset.errorPath) ?? ''),
          time: _extractPath(data, preset.timePath) ?? '${end.difference(start).inMilliseconds} ms',
          memory: _extractPath(data, preset.memoryPath) ?? '',
        );
      } catch (e) {
        // If not JSON, dump raw
        state = state.copyWith(
          isRunning: false,
          stdout: response.body,
          time: '${end.difference(start).inMilliseconds} ms',
        );
      }
    } else {
      state = state.copyWith(
        isRunning: false,
        isError: true,
        stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  String _escapeJson(String input) {
    return input.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r');
  }

  String? _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
