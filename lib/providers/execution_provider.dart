import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';
import 'preset_provider.dart';
import 'file_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

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

  Future<void> runCode() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) return;

    final code = activeFile.content;

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final settings = ref.read(settingsProvider);

    try {
      if (settings.useDefaultOneCompiler) {
        await _runOneCompiler(code);
      } else {
        await _runCustomPreset(code);
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> _runOneCompiler(String code) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final apiKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'language': 'dart',
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      }),
    );

    _parseAndSetOutput(
      response.body,
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
    );
  }

  Future<void> _runCustomPreset(String code) async {
    final presetState = ref.read(presetProvider);
    final preset = presetState.activePreset;

    if (preset == null) {
      state = state.copyWith(isRunning: false, stderr: 'No custom preset selected.');
      return;
    }

    if (preset.endpointUrl.isEmpty || !preset.endpointUrl.startsWith('http')) {
      state = state.copyWith(isRunning: false, stderr: 'Invalid endpoint URL.');
      return;
    }

    final headers = <String, String>{};
    for (var h in preset.headers) {
      headers[h.key] = h.value.replaceAll('{auth}', preset.authValue);
    }

    if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
      final bytes = utf8.encode(preset.authValue);
      final base64Str = base64.encode(bytes);
      headers['Authorization'] = 'Basic $base64Str';
    } else if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
      // If not already replaced via {auth}
      if (!headers.values.any((v) => v.contains(preset.authValue))) {
         // Usually handled by headers table, but fallback:
         // Cannot guess header name, so better rely on {auth} substitution in header table
      }
    }

    final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final bodyStr = preset.requestBodyTemplate
        .replaceAll('{code}', '"$safeCode"')
        .replaceAll('{language}', '"dart"')
        .replaceAll('{stdin}', '""');

    Uri uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      final queryParams = Map<String, String>.from(uri.queryParameters);
      for (var q in preset.queryParams) {
        queryParams[q.key] = q.value.replaceAll('{auth}', preset.authValue);
      }
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response response;

    try {
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      _parseAndSetOutput(
        response.body,
        stdoutPath: preset.stdoutPath,
        stderrPath: preset.stderrPath,
        errorPath: preset.errorPath,
        executionTimePath: preset.executionTimePath,
        memoryPath: preset.memoryPath,
      );

    } catch(e) {
      state = state.copyWith(isRunning: false, stderr: 'Request failed: ${e.toString()}');
    }
  }

  void _parseAndSetOutput(String responseBody, {
    String? stdoutPath,
    String? stderrPath,
    String? errorPath,
    String? executionTimePath,
    String? memoryPath,
  }) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;

      String stdout = _resolvePath(json, stdoutPath) ?? '';
      String stderr = _resolvePath(json, stderrPath) ?? '';
      String error = _resolvePath(json, errorPath) ?? '';
      String execTime = _resolvePath(json, executionTimePath) ?? '';
      String mem = _resolvePath(json, memoryPath) ?? '';

      if (error.isNotEmpty && stderr.isEmpty) {
        stderr = error;
      }

      state = state.copyWith(
        isRunning: false,
        stdout: stdout,
        stderr: stderr,
        executionTime: execTime,
        memory: mem,
      );
    } catch (e) {
      // If not JSON, dump raw text
      state = state.copyWith(
        isRunning: false,
        stdout: responseBody,
      );
    }
  }

  String? _resolvePath(Map<String, dynamic> json, String? path) {
    if (path == null || path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
