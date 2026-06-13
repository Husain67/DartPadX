import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../data/models/compiler_preset.dart';

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
  static Future<ExecutionResult> executeDefault({
    required String code,
    required String stdin,
  }) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': AppConstants.defaultOneCompilerKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
    };
    final body = jsonEncode({
      'language': 'dart',
      'stdin': stdin,
      'files': [
        {
          'name': 'main.dart',
          'content': code
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          executionTime: data['executionTime']?.toString() ?? '',
          memory: '',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: \\${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Request Failed',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  static Future<ExecutionResult> executeCustom({
    required CompilerPreset preset,
    required String code,
    required String stdin,
  }) async {
    try {
      // Build headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header') {
        headers['Authorization'] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer \\${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic \\$encoded';
      }

      // Build query params
      var uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty || preset.authType == 'Query Param') {
        final params = Map<String, String>.from(preset.queryParams);
        if (preset.authType == 'Query Param') {
          // Simplistic implementation, assumes format key=value
          if (preset.authValue.contains('=')) {
            final parts = preset.authValue.split('=');
            params[parts[0]] = parts[1];
          }
        }
        uri = uri.replace(queryParameters: params);
      }

      // Build body
      String body = preset.requestBodyTemplate;
      // Simple replace, for json safety we encode and strip quotes
      String safeCode = jsonEncode(code);
      safeCode = safeCode.substring(1, safeCode.length - 1);

      String safeStdin = jsonEncode(stdin);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1);

      body = body.replaceAll('{code}', safeCode);
      body = body.replaceAll('{stdin}', safeStdin);
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractPath(data, preset.stdoutPath),
          stderr: _extractPath(data, preset.stderrPath),
          error: _extractPath(data, preset.errorPath),
          executionTime: _extractPath(data, preset.timePath),
          memory: _extractPath(data, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: \\${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Request Failed',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  static String _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
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
