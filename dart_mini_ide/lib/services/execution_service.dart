import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
  });
}

class ExecutionService {
  static const String _defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';

  static Future<ExecutionResult> executeCode(String code, CompilerPreset? preset) async {
    if (preset == null || preset.name == 'OneCompiler') {
      return _executeOneCompiler(code);
    } else {
      return _executeCustomPreset(code, preset);
    }
  }

  static Future<ExecutionResult> _executeOneCompiler(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_defaultOneCompilerUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        body: jsonEncode({
          "language": "dart",
          "stdin": "",
          "files": [
            {
              "name": "main.dart",
              "content": code
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          executionTime: data['executionTime'].toString(),
          memory: data['limitRemaining'].toString(),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}',
          error: response.body,
          executionTime: '0',
          memory: '0',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '0',
        memory: '0',
      );
    }
  }

  static Future<ExecutionResult> _executeCustomPreset(String code, CompilerPreset preset) async {
    try {
      final uri = Uri.parse(preset.endpointUrl);
      var queryParams = Map<String, dynamic>.from(uri.queryParameters);
      if (preset.queryParams.isNotEmpty) {
        queryParams.addAll(preset.queryParams);
      }
      final finalUri = uri.replace(queryParameters: queryParams);

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header') {
        final parts = preset.authValue.split(':');
        if (parts.length == 2) {
          headers[parts[0].trim()] = parts[1].trim();
        }
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      }

      String bodyStr = preset.requestBodyTemplate;
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''));
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(finalUri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(finalUri, headers: headers);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractValue(data, preset.stdoutPath),
          stderr: _extractValue(data, preset.stderrPath),
          error: _extractValue(data, preset.errorPath),
          executionTime: _extractValue(data, preset.executionTimePath),
          memory: _extractValue(data, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}',
          error: response.body,
          executionTime: '0',
          memory: '0',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '0',
        memory: '0',
      );
    }
  }

  static String _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
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
