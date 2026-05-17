import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';
import 'compiler_preset_provider.dart';
import 'file_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String metrics;
  final String rawResponse;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.metrics = '',
    this.rawResponse = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? metrics,
    String? rawResponse,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      metrics: metrics ?? this.metrics,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    final code = activeFile.content;
    final stdin = ref.read(stdinProvider);
    final settings = ref.read(settingsProvider);
    final presets = ref.read(compilerPresetProvider);

    CompilerPreset? preset;

    if (settings.useDefaultOneCompiler) {
      preset = presets.firstWhere((p) => p.name == 'OneCompiler', orElse: () => _getDefaultOneCompiler());
    } else {
      if (settings.activePresetId != null) {
        try {
          preset = presets.firstWhere((p) => p.id == settings.activePresetId);
        } catch (_) {}
      }
      if (preset == null) {
         state = state.copyWith(stderr: 'No active compiler preset selected. Please check Settings.', isRunning: false);
         return;
      }
    }

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', metrics: '', rawResponse: '');

    try {
      await _runWithPreset(preset, code, stdin);
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Execution Error: $e');
    }
  }

  Future<void> _runWithPreset(CompilerPreset preset, String code, String stdin) async {
    if (preset.endpointUrl.isEmpty) {
      state = state.copyWith(isRunning: false, stderr: 'Endpoint URL is empty in preset.');
      return;
    }

    final uri = Uri.parse(preset.endpointUrl).replace(
      queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
    );

    final headers = Map<String, String>.from(preset.headers);

    if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      headers['Authorization'] = 'Basic $encoded';
    }

    String body = preset.requestBodyTemplate;

    // Safely replace placeholders preventing JSON breaking
    String codeEscaped = jsonEncode(code);
    codeEscaped = codeEscaped.substring(1, codeEscaped.length - 1); // remove surrounding quotes

    String stdinEscaped = jsonEncode(stdin);
    stdinEscaped = stdinEscaped.substring(1, stdinEscaped.length - 1);

    body = body.replaceAll('{code}', codeEscaped);
    body = body.replaceAll('{stdin}', stdinEscaped);
    body = body.replaceAll('{language}', 'dart');

    http.Response response;
    final stopwatch = Stopwatch()..start();

    if (preset.httpMethod == 'POST') {
      response = await http.post(uri, headers: headers, body: body);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(uri, headers: headers, body: body);
    } else {
      // GET
      response = await http.get(uri, headers: headers);
    }

    stopwatch.stop();
    final timeMs = stopwatch.elapsedMilliseconds;

    state = state.copyWith(rawResponse: response.body, isRunning: false);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _parseResponse(preset, response.body, timeMs);
    } else {
      state = state.copyWith(
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          isRunning: false);
    }
  }

  void _parseResponse(CompilerPreset preset, String responseBody, int requestTimeMs) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      String extractValue(String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = json;
        for (var part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      final stdout = extractValue(preset.stdoutPath);
      final stderr = extractValue(preset.stderrPath);
      final error = extractValue(preset.errorPath);
      final execTime = extractValue(preset.executionTimePath);
      final memory = extractValue(preset.memoryPath);

      String combinedStderr = '';
      if (stderr.isNotEmpty) combinedStderr += '$stderr\n';
      if (error.isNotEmpty) combinedStderr += error;

      String metrics = 'Request Time: ${requestTimeMs}ms';
      if (execTime.isNotEmpty) metrics += ' | Exec Time: $execTime';
      if (memory.isNotEmpty) metrics += ' | Memory: $memory';

      state = state.copyWith(
        stdout: stdout,
        stderr: combinedStderr.trim(),
        metrics: metrics,
      );
    } catch (e) {
      // Not JSON or parsing error
      state = state.copyWith(
        stdout: responseBody, // Fallback to raw
        stderr: 'Failed to parse JSON response. Check mapping paths.',
        metrics: 'Request Time: ${requestTimeMs}ms',
      );
    }
  }

  CompilerPreset _getDefaultOneCompiler() {
    return CompilerPreset(
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'X-RapidAPI-Key',
      authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      headers: {'Content-Type': 'application/json'},
      requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
    );
  }
}
