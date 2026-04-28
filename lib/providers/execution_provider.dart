import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'compiler_provider.dart';
import 'settings_provider.dart';
import '../models/compiler_preset.dart';

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
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> runCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final settings = _ref.read(settingsProvider);
    final compilerState = _ref.read(compilerProvider);

    CompilerPreset preset;
    if (settings.useDefaultOneCompiler) {
      preset = compilerState.presets.firstWhere((p) => p.name == 'OneCompiler');
    } else {
      final p = _ref.read(compilerProvider.notifier).activePreset;
      if (p == null) {
        state = state.copyWith(isRunning: false, stderr: 'No preset selected.');
        return;
      }
      preset = p;
    }

    try {
      final response = await _executeRequest(preset, code, stdin);
      _parseResponse(preset, response);
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: e.toString());
    }
  }

  Future<String> testConnection(CompilerPreset preset) async {
    const testCode = "void main() { print('Connection successful'); }";
    try {
      final response = await _executeRequest(preset, testCode, '');
      return response.body;
    } catch (e) {
      return e.toString();
    }
  }

  Future<http.Response> _executeRequest(CompilerPreset preset, String code, String stdin) async {
    final uri = Uri.parse(preset.endpoint);
    Map<String, String> headers = {};

    for (var h in preset.headers) {
      headers[h.key] = h.value;
    }

    if (preset.authType == 'API-Key Header') {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final token = base64Encode(utf8.encode('${preset.authKey}:${preset.authValue}'));
      headers['Authorization'] = 'Basic $token';
    }

    String finalUri = uri.toString();
    if (preset.authType == 'Query Param') {
      finalUri += "${finalUri.contains('?') ? '&' : '?'}${preset.authKey}=${preset.authValue}";
    }
    for (var q in preset.queryParams) {
      finalUri += "${finalUri.contains('?') ? '&' : '?'}${q.key}=${q.value}";
    }

    String bodyStr = preset.bodyTemplate;

    // Proper JSON replacement removing the quotes if bodyTemplate wraps {code} in quotes.
    http.Response response;
    final url = Uri.parse(finalUri);

    if (headers['Content-Type'] == 'application/x-www-form-urlencoded') {
       bodyStr = bodyStr.replaceAll('{code}', Uri.encodeQueryComponent(code));
       bodyStr = bodyStr.replaceAll('{stdin}', Uri.encodeQueryComponent(stdin));
       bodyStr = bodyStr.replaceAll('{language}', 'dart');

       if (preset.method == 'GET') {
         response = await http.get(url, headers: headers);
       } else if (preset.method == 'PUT') {
         response = await http.put(url, headers: headers, body: bodyStr);
       } else {
         response = await http.post(url, headers: headers, body: bodyStr);
       }
    } else {
       String encodedCode = jsonEncode(code);
       encodedCode = encodedCode.substring(1, encodedCode.length - 1);

       String encodedStdin = jsonEncode(stdin);
       encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

       bodyStr = bodyStr.replaceAll('{code}', encodedCode);
       bodyStr = bodyStr.replaceAll('{stdin}', encodedStdin);
       bodyStr = bodyStr.replaceAll('{language}', 'dart');

       if (preset.method == 'GET') {
         response = await http.get(url, headers: headers);
       } else if (preset.method == 'PUT') {
         response = await http.put(url, headers: headers, body: bodyStr);
       } else {
         response = await http.post(url, headers: headers, body: bodyStr);
       }
    }

    return response;
  }

  void _parseResponse(CompilerPreset preset, http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'HTTP Error ${response.statusCode}: \n${response.body}'
      );
      return;
    }

    try {
      final json = jsonDecode(response.body);

      String extract(String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = json;
        for (var p in parts) {
          if (current is Map && current.containsKey(p)) {
            current = current[p];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      final stdout = extract(preset.stdoutPath);
      final stderr = extract(preset.stderrPath);
      final error = extract(preset.errorPath);
      final execTime = extract(preset.executionTimePath);
      final mem = extract(preset.memoryPath);

      state = state.copyWith(
        isRunning: false,
        stdout: stdout,
        stderr: stderr.isNotEmpty ? stderr : error,
        executionTime: execTime,
        memory: mem,
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, stdout: response.body, stderr: 'Failed to parse JSON response. Showing raw response.');
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
