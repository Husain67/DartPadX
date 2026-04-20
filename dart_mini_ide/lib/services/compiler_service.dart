import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerService {
  Future<Map<String, dynamic>> executeCode(
      String code, String stdin, CompilerPreset preset) async {
    final Map<String, String> resolvedHeaders = {};
    preset.headers.forEach((key, value) {
      resolvedHeaders[key] = value.replaceAll('{authValue}', preset.authValue);
    });

    if (preset.authType == 'Bearer Token') {
      resolvedHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encodedAuth = base64Encode(utf8.encode(preset.authValue));
      resolvedHeaders['Authorization'] = 'Basic $encodedAuth';
    }

    final Map<String, String> resolvedParams = {};
    preset.queryParams.forEach((key, value) {
      resolvedParams[key] = value.replaceAll('{authValue}', preset.authValue);
    });

    final uri = resolvedParams.isEmpty ? Uri.parse(preset.endpoint) : Uri.parse(preset.endpoint).replace(queryParameters: resolvedParams);

    String resolvedBody = preset.bodyTemplate
        .replaceAll('{stdin}', _escapeJsonString(stdin))
        .replaceAll('{language}', 'dart');

    final codePlaceholderPattern = RegExp(r'\{code\}');
    resolvedBody = resolvedBody.replaceAllMapped(codePlaceholderPattern, (match) {
        return _escapeJsonString(code);
    });


    http.Response response;
    final startTime = DateTime.now();
    try {
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: resolvedHeaders);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: resolvedHeaders, body: resolvedBody);
      } else {
        response = await http.post(uri, headers: resolvedHeaders, body: resolvedBody);
      }

      final executionTimeMs = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'stdout': _extractValue(data, preset.mappings['stdout']),
          'stderr': _extractValue(data, preset.mappings['stderr']),
          'error': _extractValue(data, preset.mappings['error']),
          'executionTime': _extractValue(data, preset.mappings['executionTime']) ?? '${executionTimeMs}ms',
          'memory': _extractValue(data, preset.mappings['memory']),
          'rawResponse': response.body,
        };
      } else {
         return {
          'stdout': null,
          'stderr': null,
          'error': 'HTTP Error: ${response.statusCode} - ${response.body}',
          'executionTime': '${executionTimeMs}ms',
          'memory': null,
          'rawResponse': response.body,
        };
      }
    } catch (e) {
      return {
          'stdout': null,
          'stderr': null,
          'error': 'Network/Execution Error: $e',
          'executionTime': null,
          'memory': null,
          'rawResponse': null,
        };
    }
  }

  String _escapeJsonString(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r');
  }

  dynamic _extractValue(Map<String, dynamic> data, String? path) {
    if (path == null || path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
