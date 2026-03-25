import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_presets_provider.dart';

final executionProvider =
    StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
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
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    final preset = _ref.read(compilerPresetsProvider).activePreset;
    if (preset == null) {
      state = state.copyWith(stderr: 'Error: No compiler preset selected.');
      return;
    }

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

      var bodyStr = preset.bodyTemplate
          .replaceAll('{code}', '"\$safeCode"')
          .replaceAll('{stdin}', safeStdin)
          .replaceAll('{language}', 'dart');

      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header') {
        // Assume API-Key is manually placed in headers via UI,
        // but if there's a specific header pattern wanted we can add it here.
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer \${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final basicAuth = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic \$basicAuth';
      }

      var uri = Uri.parse(preset.url);

      final queryParams = Map<String, String>.from(preset.queryParams);
      if (preset.authType == 'Query Param') {
        // Assume the key is known or just append the value, usually it's `api_key`
        // We'll trust the user added it to queryParams if they used this authType,
        // or we can blindly append an `api_key` parameter.
        if (preset.authValue.isNotEmpty) {
          queryParams['api_key'] = preset.authValue;
        }
      }

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;

      final sw = Stopwatch()..start();

      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      sw.stop();

      String out = '';
      String err = '';
      String execErr = '';
      String execTime = '';
      String execMemory = '';

      try {
        final jsonResp = jsonDecode(response.body);

        out = _extractPath(jsonResp, preset.stdoutPath);
        err = _extractPath(jsonResp, preset.stderrPath);
        execErr = _extractPath(jsonResp, preset.errorPath);

        execTime = _extractPath(jsonResp, preset.executionTimePath);
        execMemory = _extractPath(jsonResp, preset.memoryPath);
      } catch (e) {
        // Not JSON
        if (response.statusCode == 200) {
          out = response.body;
        } else {
          err = response.body;
        }
      }

      String finalErr = err;
      if (execErr.isNotEmpty) {
        finalErr += (finalErr.isNotEmpty ? '\n' : '') + execErr;
      }
      if (response.statusCode != 200 && finalErr.isEmpty) {
         finalErr = 'HTTP Error \${response.statusCode}: \${response.body}';
      }

      state = state.copyWith(
        isRunning: false,
        stdout: out,
        stderr: finalErr,
        executionTime: execTime.isEmpty ? '\${sw.elapsedMilliseconds} ms' : execTime,
        memory: execMemory,
      );

    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: \$e',
      );
    }
  }

  String _extractPath(dynamic json, String path) {
    if (path.isEmpty || json == null) return '';
    try {
      final parts = path.split('.');
      dynamic current = json;
      for (final part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return '';
        }
      }
      return current?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}
