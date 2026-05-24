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

class CompilerService {
  static Future<ExecutionResult> executeCode({
    required CompilerPreset preset,
    required String code,
    required String stdin,
    required String language, // usually "dart"
  }) async {
    Map<String, String> resolvedHeaders = {};
    preset.headers.forEach((key, value) {
      if (value.contains('{authValue}')) {
        resolvedHeaders[key] = value.replaceAll('{authValue}', preset.authValue);
      } else {
        resolvedHeaders[key] = value;
      }
    });

    if (preset.authType == 'Bearer Token') {
      resolvedHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      resolvedHeaders['Authorization'] = 'Basic $encoded';
    } else if (preset.authType == 'API-Key Header' && !resolvedHeaders.values.any((v) => v.contains(preset.authValue))) {
       // Fallback if user didn't specify exactly where
       resolvedHeaders['x-api-key'] = preset.authValue;
    }

    Uri uri = Uri.parse(preset.endpoint);
    if (preset.queryParams.isNotEmpty || preset.authType == 'Query Param') {
      Map<String, String> query = Map.from(preset.queryParams);
      if (preset.authType == 'Query Param') {
        // assume api_key by default if not set
        query['api_key'] = preset.authValue;
      }
      uri = uri.replace(queryParameters: query);
    }

    String bodyStr = preset.bodyTemplate
        .replaceAll('"{code}"', jsonEncode(code))
        .replaceAll('"{stdin}"', jsonEncode(stdin))
        .replaceAll('{language}', language);

    http.Response response;
    try {
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: resolvedHeaders, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: resolvedHeaders);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: resolvedHeaders, body: bodyStr);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.method}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _resolvePath(data, preset.stdoutPath) ?? '',
          stderr: _resolvePath(data, preset.stderrPath) ?? '',
          error: _resolvePath(data, preset.errorPath) ?? '',
          executionTime: _resolvePath(data, preset.executionTimePath)?.toString() ?? '',
          memory: _resolvePath(data, preset.memoryPath)?.toString() ?? '',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP ${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  static dynamic _resolvePath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
