import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

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

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final settings = ref.read(settingsProvider);
    final stdin = ref.read(stdinProvider);

    CompilerPreset? preset;

    if (settings.useDefaultOneCompiler) {
      final compilerState = ref.read(compilerProvider);
      preset = compilerState.presets.firstWhere(
        (p) => p.name == 'OneCompiler',
        orElse: () => _getFallbackOneCompiler(),
      );
    } else {
      final compilerState = ref.read(compilerProvider);
      preset = compilerState.activePreset;
    }

    if (preset == null) {
      state = state.copyWith(error: 'No valid compiler preset selected.');
      return;
    }

    state = ExecutionState(isRunning: true);

    try {
      final response = await _makeRequest(preset, activeFile.content, stdin);
      _parseResponse(preset, response);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: 'Execution failed: \${e.toString()}',
      );
    }
  }

  CompilerPreset _getFallbackOneCompiler() {
    return CompilerPreset(
      id: 'fallback_oc',
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': '{authValue}',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      queryParams: {},
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      responseMapping: {
        'stdout': 'stdout',
        'stderr': 'stderr',
        'error': 'exception',
        'executionTime': 'executionTime',
        'memory': ''
      },
    );
  }

  Future<http.Response> _makeRequest(CompilerPreset preset, String code, String stdin) async {
    final uri = Uri.parse(preset.endpointUrl).replace(
      queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
    );

    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
      headers.forEach((key, value) {
        if (value.contains('{authValue}')) {
          headers[key] = value.replaceAll('{authValue}', preset.authValue);
        }
      });
    } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
      headers['Authorization'] = 'Bearer \${preset.authValue}';
    } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
      final enc = base64Encode(utf8.encode(preset.authValue));
      headers['Authorization'] = 'Basic $enc';


    }

    String bodyStr = preset.bodyTemplate
        .replaceAll('"{code}"', jsonEncode(code))
        .replaceAll('"{stdin}"', jsonEncode(stdin));

    if (preset.httpMethod.toUpperCase() == 'POST') {
      return await http.post(uri, headers: headers, body: bodyStr);
    } else if (preset.httpMethod.toUpperCase() == 'PUT') {
      return await http.put(uri, headers: headers, body: bodyStr);
    } else {
      return await http.get(uri, headers: headers);
    }
  }

  void _parseResponse(CompilerPreset preset, http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          isRunning: false,
          stdout: _extractPath(data, preset.responseMapping['stdout']),
          stderr: _extractPath(data, preset.responseMapping['stderr']),
          error: _extractPath(data, preset.responseMapping['error']),
          executionTime: _extractPath(data, preset.responseMapping['executionTime']),
          memory: _extractPath(data, preset.responseMapping['memory']),
        );
      } catch (e) {
        state = state.copyWith(
          isRunning: false,
          error: 'Failed to parse JSON response: \${response.body}',
        );
      }
    } else {
      state = state.copyWith(
        isRunning: false,
        error: 'HTTP Error \${response.statusCode}: \${response.body}',
      );
    }
  }

  String _extractPath(dynamic data, String? path) {
    if (path == null || path.isEmpty || data == null) return '';

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
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
