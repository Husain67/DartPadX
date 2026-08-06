import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionService {
  static Future<Map<String, String>> execute({
    required String code,
    required CompilerPreset preset,
  }) async {
    try {
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        // Find header with '{auth}' and replace it
        headers.forEach((key, value) {
          if (value.contains('{auth}')) {
            headers[key] = value.replaceAll('{auth}', preset.authValue);
          }
        });
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      String bodyStr = preset.requestBodyTemplate;
      bodyStr = bodyStr.replaceAll('"{code}"', jsonEncode(code));
      bodyStr = bodyStr.replaceAll('"{stdin}"', jsonEncode("")); // Add stdin support later
      bodyStr = bodyStr.replaceAll('"{language}"', jsonEncode("dart"));

      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'stdout': _extractPath(data, preset.stdoutPath) ?? '',
          'stderr': _extractPath(data, preset.stderrPath) ?? '',
          'error': _extractPath(data, preset.errorPath) ?? '',
          'time': _extractPath(data, preset.timePath) ?? '',
          'memory': _extractPath(data, preset.memoryPath) ?? '',
          'raw': response.body,
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'HTTP ${response.statusCode}: ${response.body}',
          'error': '',
          'time': '',
          'memory': '',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Exception: $e',
        'error': '',
        'time': '',
        'memory': '',
      };
    }
  }

  static String? _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
