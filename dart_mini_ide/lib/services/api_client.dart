import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiClient {
  Future<Map<String, String>> executeCode({
    required String code,
    required CompilerPreset preset,
    String stdinInput = '',
  }) async {
    final Map<String, String> result = {
      'stdout': '',
      'stderr': '',
      'error': '',
      'executionTime': '',
      'memory': '',
    };

    try {
      final uri = Uri.parse(preset.endpointUrl);
      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header' && preset.authValue != null) {
        // Headers handled correctly in configuration or explicitly here if needed
      } else if (preset.authType == 'Bearer Token' && preset.authValue != null) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
        final encodedAuth = base64Encode(utf8.encode(preset.authValue!));
        headers['Authorization'] = 'Basic $encodedAuth';
      }

      final queryParams = Map<String, String>.from(preset.queryParams);
      final finalUri = uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      String body = preset.bodyTemplate.replaceAll('{code}', jsonEncode(code));
      body = body.replaceAll('{language}', 'dart');

      // Prevent invalid JSON strings by safely encoding the stdin
      String safeStdin = jsonEncode(stdinInput);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1); // remove outer quotes from json encode to insert correctly in string template

      body = body.replaceAll('{stdin}', safeStdin);

      http.Response response;

      if (preset.httpMethod == 'POST') {
        response = await http.post(finalUri, headers: headers, body: body);
      } else if (preset.httpMethod == 'GET') {
        response = await http.get(finalUri, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.httpMethod}');
      }

      final jsonResponse = jsonDecode(response.body);

      result['stdout'] = _extractFromJson(jsonResponse, preset.stdoutPath) ?? '';
      result['stderr'] = _extractFromJson(jsonResponse, preset.stderrPath) ?? '';
      result['error'] = _extractFromJson(jsonResponse, preset.errorPath) ?? '';
      result['executionTime'] = _extractFromJson(jsonResponse, preset.executionTimePath) ?? '';
      result['memory'] = _extractFromJson(jsonResponse, preset.memoryPath) ?? '';

    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  String? _extractFromJson(dynamic json, String path) {
    if (path.isEmpty || json == null) return null;

    final keys = path.split('.');
    dynamic current = json;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current.toString();
  }
}