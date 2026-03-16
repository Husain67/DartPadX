import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  Future<void> executeCode(String code) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final settings = _ref.read(settingsProvider);

    if (settings.useDefaultCompiler) {
      await _executeDefault(code);
    } else {
      await _executeCustom(code, settings);
    }
  }

  Future<void> _executeDefault(String code) async {
    try {
      const defaultKey = String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

      final request = http.Request('POST', Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'));

      request.headers.addAll({
        'content-type': 'application/json',
        'X-RapidAPI-Key': defaultKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      });

      request.body = json.encode({
        "language": "dart",
        "stdin": "",
        "files": [
          {
            "name": "main.dart",
            "content": code
          }
        ]
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        state = state.copyWith(
          isExecuting: false,
          stdout: jsonResponse['stdout'] ?? '',
          stderr: jsonResponse['stderr'] ?? '',
          executionTime: jsonResponse['executionTime']?.toString() ?? '',
          memory: '',
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'Error: ${response.statusCode}\n$responseBody',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Exception: $e',
      );
    }
  }

  Future<void> _executeCustom(String code, SettingsState settings) async {
    final activePresetId = settings.activePresetId;
    if (activePresetId == null) {
      state = state.copyWith(isExecuting: false, stderr: 'No custom compiler preset selected.');
      return;
    }

    final preset = settings.presets.firstWhere((p) => p.id == activePresetId);

    try {
      final uri = Uri.parse(preset.endpoint).replace(queryParameters: preset.queryParams.isEmpty ? null : preset.queryParams);
      final request = http.Request(preset.method, uri);

      request.headers.addAll(preset.headers);

      String body = preset.requestBodyTemplate;
      body = body.replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''));
      body = body.replaceAll('{language}', 'dart');
      body = body.replaceAll('{stdin}', '');

      request.body = body;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(responseBody);

        String stdout = _resolvePath(jsonResponse, preset.stdoutPath);
        String stderr = _resolvePath(jsonResponse, preset.stderrPath);
        String error = _resolvePath(jsonResponse, preset.errorPath);
        String executionTime = _resolvePath(jsonResponse, preset.executionTimePath);
        String memory = _resolvePath(jsonResponse, preset.memoryPath);

        state = state.copyWith(
          isExecuting: false,
          stdout: stdout.isNotEmpty ? stdout : '',
          stderr: stderr.isNotEmpty ? stderr : error,
          executionTime: executionTime,
          memory: memory,
        );
      } else {
         state = state.copyWith(
          isExecuting: false,
          stderr: 'Custom API Error: ${response.statusCode}\n$responseBody',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Custom API Exception: $e',
      );
    }
  }

  String _resolvePath(Map<String, dynamic> jsonResponse, String path) {
    if (path.isEmpty) return '';
    final keys = path.split('.');
    dynamic current = jsonResponse;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
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
