import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dart_mini_ide/models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class CompilerService {
  static Future<ExecutionResult> executeCode(
      String code, String stdin, CompilerPreset preset) async {
    try {
      final uri = Uri.parse(preset.endpoint).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Header' && preset.authKey.isNotEmpty) {
        headers[preset.authKey] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      }

      String bodyStr = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
          .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
          .replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractPath(data, preset.stdoutPath) ?? '',
          stderr: _extractPath(data, preset.stderrPath) ?? '',
          error: _extractPath(data, preset.errorPath) ?? '',
          executionTime: _extractPath(data, preset.timePath)?.toString() ?? '',
          memory: _extractPath(data, preset.memoryPath)?.toString() ?? '',
        );
      } else {
        return ExecutionResult(
          error: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ExecutionResult(error: e.toString());
    }
  }

  static dynamic _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
