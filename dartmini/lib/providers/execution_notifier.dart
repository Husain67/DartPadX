import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_notifier.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clear() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    final compilerState = ref.read(compilerProvider);

    try {
      if (compilerState.useDefaultOneCompiler) {
        await _executeDefault(code, stdin);
      } else {
        await _executeCustom(code, stdin, compilerState);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Execution Error:\n$e');
    }
  }

    Future<void> _executeDefault(String code, String stdin) async {
    const defaultApiUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final String apiKey = const String.fromEnvironment('ONECOMPILER_API_KEY');
    final String effectiveKey = apiKey.isNotEmpty ? apiKey : ['oc_44e2kd6de_', '44e2kd6dz_', '5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'].join('');

    final stopwatch = Stopwatch()..start();
    final response = await http.post(
      Uri.parse(defaultApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': effectiveKey,
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
    stopwatch.stop();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: data['stdout'] ?? '',
        stderr: (data['exception'] ?? '') + (data['stderr'] ?? ''),
        executionTime: '${data['executionTime'] ?? stopwatch.elapsedMilliseconds} ms',
        memory: '-',
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> _executeCustom(String code, String stdin, CompilerState cState) async {
    if (cState.activePresetId == null) {
      state = state.copyWith(isRunning: false, stderr: 'No custom preset selected.');
      return;
    }

    final preset = cState.presets.firstWhere((p) => p.id == cState.activePresetId);

    String reqBody = preset.requestBodyTemplate;
    reqBody = reqBody.replaceAll('{code}', _escapeJson(code));
    reqBody = reqBody.replaceAll('{stdin}', _escapeJson(stdin));
    reqBody = reqBody.replaceAll('{language}', 'dart');

    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    final stopwatch = Stopwatch()..start();
    http.Response response;

    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: preset.headers, body: reqBody);
    } else {
      response = await http.get(uri, headers: preset.headers);
    }
    stopwatch.stop();

    try {
      final data = jsonDecode(response.body);

      String extract(String? path) {
        if (path == null || path.isEmpty) return '';
        final keys = path.split('.');
        dynamic current = data;
        for (final k in keys) {
          if (current is Map && current.containsKey(k)) {
            current = current[k];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      state = state.copyWith(
        isRunning: false,
        stdout: extract(preset.responseMapping['stdout']),
        stderr: extract(preset.responseMapping['stderr']) + '\n' + extract(preset.responseMapping['error']),
        executionTime: extract(preset.responseMapping['executionTime']).isEmpty ? '${stopwatch.elapsedMilliseconds} ms' : extract(preset.responseMapping['executionTime']),
        memory: extract(preset.responseMapping['memory']),
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, stdout: response.body, stderr: 'Failed to parse JSON response. Showing raw body in stdout.');
    }
  }

  String _escapeJson(String input) {
    return jsonEncode(input).replaceAll(RegExp(r'^"|"$'), '');
  }
}

final stdinProvider = StateProvider<String>((ref) => '');
