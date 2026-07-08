import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  CompilerState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  CompilerState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return CompilerState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState());

  void clearOutput() {
    state = CompilerState();
  }

  Future<void> runCode(String code, CompilerPreset preset) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    try {
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header') {
        // Typically set via headers in UI, but could be dynamic
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final encoded = base64.encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      }

      String url = preset.endpoint;
      if (preset.queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: {...uri.queryParameters, ...preset.queryParams}).toString();
      }

      // Safe JSON encoding for code
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1);

      // Handle stdin if provided in editor (empty for now)
      String encodedStdin = "";

      String body = preset.requestBodyTemplate;

      // We must be careful not to introduce double quotes if they already exist in the template
      if (body.contains('"{code}"')) {
        body = body.replaceAll('"{code}"', '"$encodedCode"');
      } else {
        body = body.replaceAll('{code}', '"$encodedCode"');
      }

      if (body.contains('"{stdin}"')) {
        body = body.replaceAll('"{stdin}"', '"$encodedStdin"');
      } else {
        body = body.replaceAll('{stdin}', '"$encodedStdin"');
      }

      if (body.contains('"{language}"')) {
        body = body.replaceAll('"{language}"', '"dart"');
      } else {
        body = body.replaceAll('{language}', '"dart"');
      }

      http.Response response;
      final uri = Uri.parse(url);

      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.method}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String parsePath(Map<String, dynamic> json, String path) {
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

        final stdout = parsePath(data, preset.stdoutPath);
        final stderr = parsePath(data, preset.stderrPath);
        final error = parsePath(data, preset.errorPath);
        final executionTime = parsePath(data, preset.executionTimePath);
        final memory = parsePath(data, preset.memoryPath);

        String finalStderr = stderr;
        if (error.isNotEmpty && stderr.isEmpty) finalStderr = error;

        state = state.copyWith(
          isRunning: false,
          stdout: stdout,
          stderr: finalStderr,
          executionTime: executionTime,
          memory: memory,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          stderr: 'HTTP Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: $e',
      );
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
