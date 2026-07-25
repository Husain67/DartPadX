import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionService {
  static Future<Map<String, String?>> execute({
    required String code,
    required CompilerPreset preset,
    String stdin = '',
  }) async {
    final uri = Uri.parse(preset.url);

    // Prepare Headers
    final headers = <String, String>{};
    preset.headers.forEach((key, value) {
      String processedValue = value;
      if (value.contains('{authCredentials}')) {
        processedValue = processedValue.replaceAll(
            '{authCredentials}', preset.authCredentials);
      }
      headers[key] = processedValue;
    });

    if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authCredentials}';
    } else if (preset.authType == 'Basic Auth') {
      final bytes = utf8.encode(preset.authCredentials);
      final base64Str = base64.encode(bytes);
      headers['Authorization'] = 'Basic $base64Str';
    }

    // Process Query Params
    final queryParams = <String, String>{};
    preset.queryParams.forEach((key, value) {
      queryParams[key] = _substituteVariables(value, code, stdin);
    });

    final finalUri = uri.replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null);

    // Prepare Body
    String body = _substituteVariables(preset.bodyTemplate, code, stdin);

    http.Response response;

    try {
      if (preset.method == 'GET') {
        response = await http.get(finalUri, headers: headers);
      } else if (preset.method == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: body);
      } else {
        // Default to POST
        response = await http.post(finalUri, headers: headers, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return _extractOutputs(jsonResponse, preset.responseMappings);
      } else {
        return {'error': 'HTTP Error ${response.statusCode}: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Request failed: $e'};
    }
  }

  static String _substituteVariables(
      String template, String code, String stdin) {
    // Need to escape JSON special characters if substituting into JSON string
    final escapedCode = jsonEncode(code);
    final strippedCode =
        escapedCode.substring(1, escapedCode.length - 1); // remove quotes

    final escapedStdin = jsonEncode(stdin);
    final strippedStdin = escapedStdin.substring(1, escapedStdin.length - 1);

    return template
        .replaceAll('{code}', strippedCode)
        .replaceAll('{stdin}', strippedStdin)
        .replaceAll('{language}', 'dart');
  }

  static Map<String, String?> _extractOutputs(
      Map<String, dynamic> response, Map<String, String> mappings) {
    return {
      'stdout': _getValueByPath(response, mappings['stdout']),
      'stderr': _getValueByPath(response, mappings['stderr']),
      'error': _getValueByPath(response, mappings['error']),
      'time': _getValueByPath(response, mappings['executionTime']),
      'memory': _getValueByPath(response, mappings['memory']),
    };
  }

  static String? _getValueByPath(Map<String, dynamic> data, String? path) {
    if (path == null || path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;

    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }

    if (current == null) return null;
    return current.toString();
  }
}
