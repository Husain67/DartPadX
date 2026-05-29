import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset_model.dart';
import 'compiler_provider.dart';

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

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdinInput) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    final compilerState = ref.read(compilerProvider);

    if (compilerState.useDefaultOneCompiler || compilerState.activePresetId == null) {
      await _executeOneCompiler(code, stdinInput);
    } else {
      final activePreset = ref.read(compilerProvider.notifier).activePreset;
      if (activePreset != null) {
        await _executeCustomPreset(code, stdinInput, activePreset);
      } else {
        state = state.copyWith(isRunning: false, stderr: 'Error: No active preset selected.');
      }
    }
  }

  Future<void> _executeOneCompiler(String code, String stdinInput) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    const apiKey = String.fromEnvironment('API_KEY', defaultValue: String.fromEnvironment('API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'));

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'content-type': 'application/json',
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'x-rapidapi-key': apiKey,
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': stdinInput,
          'files': [
            {'name': 'main.dart', 'content': code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isRunning: false,
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '',
          executionTime: data['executionTime']?.toString() ?? '',
        );
      } else {
        state = state.copyWith(isRunning: false, stderr: 'API Error: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Exception: $e');
    }
  }

  Future<void> _executeCustomPreset(String code, String stdinInput, CompilerPresetModel preset) async {
    try {
      Uri uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        final Map<String, String> qParams = Map.from(uri.queryParameters);
        for (var param in preset.queryParams) {
          if (param.containsKey('key') && param.containsKey('value')) {
            qParams[param['key']!] = param['value']!;
          }
        }
        uri = uri.replace(queryParameters: qParams);
      }

      final Map<String, String> headers = {};
      for (var header in preset.headers) {
        if (header.containsKey('key') && header.containsKey('value')) {
          headers[header['key']!] = header['value']!;
        }
      }

      if (preset.authType == 'API-Key Header' && preset.authValue != null) {
        headers['Authorization'] = preset.authValue!;
      } else if (preset.authType == 'Bearer Token' && preset.authValue != null) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
        final encoded = base64Encode(utf8.encode(preset.authValue!));
        headers['Authorization'] = 'Basic $encoded';
        headers['Authorization'] = 'Basic $encoded';
      }

      String bodyStr = preset.bodyTemplate;
      bodyStr = bodyStr.replaceAll('{code}', _escapeJsonString(code));
      bodyStr = bodyStr.replaceAll('{stdin}', _escapeJsonString(stdinInput));
      bodyStr = bodyStr.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          state = state.copyWith(
            isRunning: false,
            stdout: _extractPath(data, preset.stdoutPath)?.toString() ?? '',
            stderr: _extractPath(data, preset.stderrPath)?.toString() ?? _extractPath(data, preset.errorPath)?.toString() ?? '',
            executionTime: _extractPath(data, preset.timePath)?.toString() ?? '',
            memory: _extractPath(data, preset.memoryPath)?.toString() ?? '',
          );
        } catch (_) {
          state = state.copyWith(isRunning: false, stdout: response.body);
        }
      } else {
        state = state.copyWith(isRunning: false, stderr: 'HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Exception: $e');
    }
  }

  String _escapeJsonString(String input) {
    return jsonEncode(input).replaceAll(RegExp(r'^"|"$'), '');
  }

  dynamic _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => '');
