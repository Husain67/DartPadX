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

class CompilerApi {
  static const String _defaultUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultKey = String.fromEnvironment('OC_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

  static Future<ExecutionResult> executeDart(String code, {CompilerPreset? preset}) async {
    if (preset == null) {
      return _executeDefault(code);
    } else {
      return _executeCustom(code, preset);
    }
  }

  static Future<ExecutionResult> _executeDefault(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_defaultUrl),
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': _defaultKey,
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
          executionTime: '${(data['executionTime'] ?? 0)} ms',
          memory: 'N/A', // OneCompiler might not return memory
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: '',
          error: 'HTTP Error \${response.statusCode}: \${response.body}',
          executionTime: '0 ms',
          memory: 'N/A',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '0 ms',
        memory: 'N/A',
      );
    }
  }

  static String _resolvePath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
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

  static Future<ExecutionResult> _executeCustom(String code, CompilerPreset preset) async {
    try {
      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header' && headers.containsKey('Authorization')) {
        // Assume already set
      } else if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
         headers['Authorization'] = 'Bearer ${headers["Authorization"] ?? ""}';
      }

      final bodyStr = preset.requestBodyTemplate
          .replaceAll('{code}', jsonEncode(code).replaceAll('^"|"\$', '')) // crude escape
          .replaceAll('{language}', 'dart')
          .replaceAll('{stdin}', '');

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _resolvePath(data, preset.stdoutPath),
          stderr: _resolvePath(data, preset.stderrPath),
          error: _resolvePath(data, preset.errorPath),
          executionTime: _resolvePath(data, preset.executionTimePath),
          memory: _resolvePath(data, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: '',
          error: 'HTTP Error \${response.statusCode}: \${response.body}',
          executionTime: '0 ms',
          memory: 'N/A',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '0 ms',
        memory: 'N/A',
      );
    }
  }
}