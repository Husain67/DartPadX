import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerService {
  Future<Map<String, dynamic>> executeCode(
    CompilerPreset preset,
    String code, {
    String stdin = '',
  }) async {
    final uri = Uri.parse(preset.url).replace(queryParameters: preset.queryParams);

    final Map<String, String> headers = Map.from(preset.headers);
    if (preset.authType == 'header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'bearer') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'basic') {
      String basicAuth = base64Encode(utf8.encode('${preset.authKey}:${preset.authValue}'));
      headers['Authorization'] = 'Basic $basicAuth';
    }

    String body = preset.bodyTemplate;

    // Attempt to parse template as JSON to safely insert code
    try {
      final templateJson = jsonDecode(preset.bodyTemplate);
      final populatedJson = _populatePlaceholders(templateJson, code, stdin);
      body = jsonEncode(populatedJson);
    } catch (e) {
      // Fallback to string replacement if template is not valid JSON (e.g. raw text or form data)
      // This is risky for JSON but necessary for flexibility
      body = body.replaceAll('{code}', _escapeJsonString(code))
                 .replaceAll('{stdin}', _escapeJsonString(stdin))
                 .replaceAll('{language}', 'dart');
    }

    final stopwatch = Stopwatch()..start();
    http.Response response;
    try {
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported method: ${preset.method}');
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Error connecting to server: $e',
        'executionTime': 0,
        'memory': 0,
        'error': e.toString(),
      };
    }
    stopwatch.stop();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final jsonResponse = jsonDecode(response.body);
        return _mapResponse(jsonResponse, preset.responseMapping, stopwatch.elapsedMilliseconds);
      } catch (e) {
        return {
          'stdout': response.body,
          'stderr': 'Failed to parse JSON response',
          'executionTime': stopwatch.elapsedMilliseconds,
          'memory': 0,
          'error': e.toString(),
        };
      }
    } else {
      return {
        'stdout': '',
        'stderr': 'HTTP ${response.statusCode}: ${response.body}',
        'executionTime': stopwatch.elapsedMilliseconds,
        'memory': 0,
        'error': 'HTTP Error',
      };
    }
  }

  dynamic _populatePlaceholders(dynamic node, String code, String stdin) {
    if (node is String) {
      return node.replaceAll('{code}', code)
                 .replaceAll('{stdin}', stdin)
                 .replaceAll('{language}', 'dart');
    } else if (node is Map) {
      return node.map((key, value) => MapEntry(key, _populatePlaceholders(value, code, stdin)));
    } else if (node is List) {
      return node.map((e) => _populatePlaceholders(e, code, stdin)).toList();
    }
    return node;
  }

  String _escapeJsonString(String str) {
    return str.replaceAll('\\', '\\\\')
              .replaceAll('"', '\\"')
              .replaceAll('\n', '\\n')
              .replaceAll('\r', '\\r')
              .replaceAll('\t', '\\t');
  }

  Map<String, dynamic> _mapResponse(
    Map<String, dynamic> json,
    Map<String, String> mapping,
    int httpTime,
  ) {
    String? stdout = _getValue(json, mapping['stdout']);
    String? stderr = _getValue(json, mapping['stderr']);
    String? error = _getValue(json, mapping['error']);

    dynamic execTimeRaw = _getValueRaw(json, mapping['executionTime']);
    dynamic memoryRaw = _getValueRaw(json, mapping['memory']);

    return {
      'stdout': stdout ?? '',
      'stderr': stderr ?? '',
      'error': error,
      'executionTime': execTimeRaw ?? httpTime,
      'memory': memoryRaw ?? 0,
    };
  }

  String? _getValue(Map<String, dynamic> json, String? path) {
    final val = _getValueRaw(json, path);
    return val?.toString();
  }

  dynamic _getValueRaw(Map<String, dynamic> json, String? path) {
    if (path == null || path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
