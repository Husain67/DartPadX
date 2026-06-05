import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionService {
  static Future<Map<String, dynamic>> executeCode({
    required CompilerPreset preset,
    required String code,
    required String stdinStr,
  }) async {
    try {
      final headers = Map<String, String>.from(preset.dynamicHeaders);

      String processedBody = preset.requestBodyTemplate;

      // Basic JSON escaping to prevent malformed payload
      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final escapedStdin = jsonEncode(stdinStr).replaceAll(RegExp(r'^"|"$'), '');

      processedBody = processedBody.replaceAll('{code}', escapedCode);
      processedBody = processedBody.replaceAll('{stdin}', escapedStdin);

      Uri uri = Uri.parse(preset.endpointUrl);
      if (preset.dynamicQueryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.dynamicQueryParams);
      }

      http.Response response;

      switch (preset.httpMethod.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: processedBody);
          break;
        case 'POST':
        default:
          response = await http.post(uri, headers: headers, body: processedBody);
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {
          'stdout': _extractValue(data, preset.stdoutPath) ?? '',
          'stderr': _extractValue(data, preset.stderrPath) ?? '',
          'error': _extractValue(data, preset.errorPath) ?? '',
          'time': _extractValue(data, preset.executionTimePath) ?? '',
          'memory': _extractValue(data, preset.memoryPath) ?? '',
          'raw': response.body,
        };
      } else {
        return {
          'stdout': '',
          'stderr': '',
          'error': 'HTTP Error \${response.statusCode}: \${response.body}',
          'time': '',
          'memory': '',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': '',
        'error': e.toString(),
        'time': '',
        'memory': '',
        'raw': '',
      };
    }
  }

  static dynamic _extractValue(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
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
