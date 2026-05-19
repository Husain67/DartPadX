import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';

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
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    final settings = ref.read(settingsProvider);

    try {
      if (settings.useDefaultOneCompiler) {
        await _executeDefaultOneCompiler(code, stdin);
      } else {
        final preset = ref.read(settingsProvider.notifier).activePreset;
        if (preset == null) {
          throw Exception('No active preset selected.');
        }
        await _executeCustomPreset(preset, code, stdin);
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: e.toString(),
      );
    }
  }

  Future<void> _executeDefaultOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

    final response = await http.post(
      url,
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
        executionTime: '${data['executionTime'] ?? 0} ms',
      );
    } else {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Error: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Future<void> _executeCustomPreset(CompilerPreset preset, String code, String stdin) async {
    // Custom Preset Logic implementation
    final urlStr = _replaceTokens(preset.endpointUrl, preset.authValue, code, stdin);
    final url = Uri.parse(urlStr);

    Map<String, String> finalHeaders = {};
    for (var entry in preset.headers.entries) {
      finalHeaders[entry.key] = _replaceTokens(entry.value, preset.authValue, code, stdin);
    }

    if (preset.authType == 'Bearer Token') {
      finalHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final basicAuth = base64Encode(utf8.encode(preset.authValue));
      finalHeaders['Authorization'] = 'Basic $basicAuth';
    } else if (preset.authType == 'API-Key Header') {
      // Assuming handled in finalHeaders if they map X-API-Key to {authValue}
    }

    // Build query params
    var uriWithParams = url;
    if (preset.queryParams.isNotEmpty) {
      Map<String, String> finalParams = {};
      for (var entry in preset.queryParams.entries) {
        finalParams[entry.key] = _replaceTokens(entry.value, preset.authValue, code, stdin);
      }
      uriWithParams = url.replace(queryParameters: finalParams);
    }

    String finalBody = _replaceTokens(preset.bodyTemplate, preset.authValue, code, stdin);

    http.Response response;

    try {
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uriWithParams, headers: finalHeaders, body: finalBody);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uriWithParams, headers: finalHeaders, body: finalBody);
      } else {
        response = await http.get(uriWithParams, headers: finalHeaders);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          data = response.body; // Not JSON
        }

        if (data is Map) {
          state = state.copyWith(
            isExecuting: false,
            stdout: _extractPath(data, preset.stdoutPath),
            stderr: _extractPath(data, preset.stderrPath),
            error: _extractPath(data, preset.errorPath),
            executionTime: _extractPath(data, preset.executionTimePath),
            memory: _extractPath(data, preset.memoryPath),
          );
        } else {
          state = state.copyWith(
            isExecuting: false,
            stdout: data.toString(),
          );
        }
      } else {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'HTTP Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Network Error: $e',
      );
    }
  }

  String _replaceTokens(String template, String auth, String code, String stdin) {
    if (template.isEmpty) return template;

    // For replacing code inside JSON strings properly, we need to escape backslashes and quotes
    final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

    return template
        .replaceAll('{authValue}', auth)
        .replaceAll('{code}', safeCode)
        .replaceAll('{stdin}', safeStdin)
        .replaceAll('{language}', 'dart');
  }

  String _extractPath(Map data, String path) {
    if (path.isEmpty) return '';
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
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

final stdinProvider = StateProvider<String>((ref) => '');
