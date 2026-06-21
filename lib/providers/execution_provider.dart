import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'compiler_provider.dart';
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool isError;
  final bool isLoading;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
    this.isError = false,
    this.isLoading = false,
  });

  factory ExecutionResult.loading() => ExecutionResult(isLoading: true);
}

class ExecutionNotifier extends StateNotifier<ExecutionResult> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionResult());

  ExecutionResult get currentState => state;

  void clear() => state = ExecutionResult();

  Future<void> executeCode(String code, String stdin) async {
    state = ExecutionResult.loading();

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.useDefaultOneCompiler
        ? compilerState.presets.firstWhere((p) => p.id == 'onecompiler')
        : compilerState.activePreset;

    try {
      final url = Uri.parse(preset.url);
      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header') {
        // Simple replace for X-RapidAPI-Key
        headers.forEach((key, value) {
          if (value.contains('{authValue}')) {
            headers[key] = value.replaceAll('{authValue}', preset.authValue);
          }
        });
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      }

      String bodyStr = preset.bodyTemplate;
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1));
      bodyStr = bodyStr.replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1));
      bodyStr = bodyStr.replaceAll('{language}', 'dart');

      http.Response response;
      final method = preset.method.toUpperCase();

      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: bodyStr);
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: bodyStr);
      } else {
        response = await http.get(url, headers: headers);
      }

      final data = jsonDecode(response.body);

      String extractPath(String path, dynamic data) {
        if (path.isEmpty || data == null) return '';
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

      final stdout = extractPath(preset.stdoutPath, data);
      final stderr = extractPath(preset.stderrPath, data);
      final error = extractPath(preset.errorPath, data);
      final time = extractPath(preset.executionTimePath, data);
      final memory = extractPath(preset.memoryPath, data);

      final isErr = response.statusCode >= 400 || stderr.isNotEmpty || error.isNotEmpty;

      state = ExecutionResult(
        stdout: stdout.isNotEmpty ? stdout : (isErr ? '' : response.body),
        stderr: stderr.isNotEmpty ? stderr : error,
        time: time,
        memory: memory,
        isError: isErr,
      );
    } catch (e) {
      state = ExecutionResult(isError: true, stderr: 'Execution Failed: $e');
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionResult>((ref) {
  return ExecutionNotifier(ref);
});
