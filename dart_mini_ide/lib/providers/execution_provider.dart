import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '');

    try {
      final settingsBox = Hive.box('settings');
      final bool useDefault = settingsBox.get('useDefaultCompiler', defaultValue: true);

      if (useDefault) {
        await _executeOneCompiler(code, stdin);
      } else {
        final String? activePresetId = settingsBox.get('activePresetId');
        if (activePresetId == null) {
          throw Exception('No custom preset selected.');
        }

        final presetsBox = Hive.box<CompilerPreset>('presets');
        final preset = presetsBox.get(activePresetId);
        if (preset == null) {
          throw Exception('Selected preset not found.');
        }

        await _executeCustomPreset(code, stdin, preset);
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: 'Execution Failed: $e',
      );
    }
  }

  Future<void> _executeOneCompiler(String code, String stdin) async {
    const defaultKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';
    const apiKey = String.fromEnvironment('ONECOMPILER_KEY', defaultValue: defaultKey);

    final response = await http.post(
      Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      body: jsonEncode({
        'language': 'dart',
        'stdin': stdin,
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(
        isExecuting: false,
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? '',
        error: data['exception'] ?? '',
        time: (data['executionTime'] ?? 0).toString(),
        memory: '',
      );
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _executeCustomPreset(String code, String stdin, CompilerPreset preset) async {
    // If the template has "{code}", user means strings with quotes included from jsonEncode.
    // Replace first if user explicitly used quotes around it like `"{code}"`
    String bodyStr = preset.requestBodyTemplate
        .replaceAll('"{code}"', jsonEncode(code))
        .replaceAll('"{stdin}"', jsonEncode(stdin))
        .replaceAll('{code}', jsonEncode(code))
        .replaceAll('{stdin}', jsonEncode(stdin))
        .replaceAll('{language}', 'dart');

    Map<String, String> headers = Map.from(preset.headers);
    if (!headers.containsKey('Content-Type')) {
        headers['Content-Type'] = 'application/json';
    }

    if (preset.authType == 'Bearer Token') {
      final token = headers['Authorization'] ?? '';
      headers['Authorization'] = 'Bearer $token';
    }

    Uri uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    http.Response response;

    final stopwatch = Stopwatch()..start();

    try {
      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
          response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String resolvePath(String path) {
            if (path.isEmpty) return '';

            final parts = path.split('.');
            dynamic current = data;

            for (var part in parts) {
                if (current is Map && current.containsKey(part)) {
                    current = current[part];
                } else {
                    return '';
                }
            }
            return current?.toString() ?? '';
        }

        state = state.copyWith(
          isExecuting: false,
          stdout: resolvePath(preset.stdoutPath),
          stderr: resolvePath(preset.stderrPath),
          error: resolvePath(preset.errorPath),
          time: resolvePath(preset.executionTimePath).isNotEmpty
              ? resolvePath(preset.executionTimePath)
              : '${stopwatch.elapsedMilliseconds}ms',
          memory: resolvePath(preset.memoryPath),
        );
      } else {
         throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }

    } catch (e) {
      stopwatch.stop();
      throw Exception('Request failed: $e');
    }
  }
}
