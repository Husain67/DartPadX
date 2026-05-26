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
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class CompilerService {
  static Future<ExecutionResult> executeCode({
    required CompilerPreset preset,
    required String code,
    String stdin = '',
    String language = 'dart',
  }) async {
    try {
      final headers = <String, String>{};
      for (var h in preset.headers) {
        if (h.containsKey('key') && h.containsKey('value')) {
          headers[h['key']!] = h['value']!;
        }
      }

      if (preset.authType == 'API-Key Header' && preset.authKey != null) {
         // Usually API keys have specific header names, assume standard ones or they add it manually.
         // If they add via Auth Type we might need to know the header name. Let's assume they set it in dynamic headers.
         // Actually, if Auth Type is Bearer, we add Authorization
      }

      if (preset.authType == 'Bearer Token' && preset.authKey != null) {
        headers['Authorization'] = 'Bearer ${preset.authKey}';
      } else if (preset.authType == 'Basic Auth' && preset.authKey != null) {
        headers['Authorization'] = 'Basic ${preset.authKey}';
      }

      var endpoint = preset.endpointUrl;
      final queryParams = <String, String>{};
      for (var q in preset.queryParams) {
         if (q.containsKey('key') && q.containsKey('value')) {
           queryParams[q['key']!] = q['value']!;
         }
      }

      if (preset.authType == 'Query Param' && preset.authKey != null) {
        // assume api_key parameter
        queryParams['api_key'] = preset.authKey!;
      }

      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(endpoint);
        endpoint = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams}).toString();
      }

      String bodyStr = preset.bodyTemplate;
      bodyStr = bodyStr.replaceAll('{code}', _escapeJsonString(code));
      bodyStr = bodyStr.replaceAll('{stdin}', _escapeJsonString(stdin));
      bodyStr = bodyStr.replaceAll('{language}', language);

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        if (!headers.containsKey('Content-Type')) {
          headers['Content-Type'] = 'application/json';
        }
        response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: bodyStr,
        );
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        if (!headers.containsKey('Content-Type')) {
          headers['Content-Type'] = 'application/json';
        }
        response = await http.put(
          Uri.parse(endpoint),
          headers: headers,
          body: bodyStr,
        );
      } else {
        response = await http.get(
          Uri.parse(endpoint),
          headers: headers,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractPath(data, preset.stdoutPath) ?? '',
          stderr: _extractPath(data, preset.stderrPath) ?? '',
          error: _extractPath(data, preset.errorPath) ?? '',
          executionTime: _extractPath(data, preset.executionTimePath) ?? '',
          memory: _extractPath(data, preset.memoryPath) ?? '',
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

  static String _escapeJsonString(String input) {
    // Escape string for JSON
    final escaped = jsonEncode(input);
    // Remove surrounding quotes added by jsonEncode
    return escaped.substring(1, escaped.length - 1);
  }

  static String? _extractPath(dynamic data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
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
