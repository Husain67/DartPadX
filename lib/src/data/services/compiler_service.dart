import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../models/execution_result.dart';

class CompilerService {
  Future<ExecutionResult> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    try {
      // Append query params to URL if they exist
      String urlString = preset.endpointUrl;
      if (preset.queryParams.isNotEmpty) {
        final queryStr = preset.queryParams.entries
            .where((e) => e.key.isNotEmpty)
            .map((e) => '\${Uri.encodeComponent(e.key)}=\${Uri.encodeComponent(e.value)}')
            .join('&');
        if (queryStr.isNotEmpty) {
           urlString += (urlString.contains('?') ? '&' : '?') + queryStr;
        }
      }

      final uri = Uri.parse(urlString);
      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'Basic Auth') {
        // Assume user puts string in headers for beta
      } else if (preset.authType == 'Bearer Token') {
        // Assume user puts in headers
      }

      String body = preset.bodyTemplate
          .replaceAll('{code}', _escapeJsonString(code))
          .replaceAll('{stdin}', _escapeJsonString(stdin))
          .replaceAll('{language}', 'dart');

      http.Response response;

      final start = DateTime.now();

      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported HTTP method: \${preset.method}');
      }

      final end = DateTime.now();
      final executionTimeStr = '\${end.difference(start).inMilliseconds} ms';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        return ExecutionResult(
          stdout: _extractValue(jsonResponse, preset.stdoutPath),
          stderr: _extractValue(jsonResponse, preset.stderrPath),
          error: _extractValue(jsonResponse, preset.errorPath),
          executionTime: preset.executionTimePath.isNotEmpty
              ? _extractValue(jsonResponse, preset.executionTimePath)
              : executionTimeStr,
          memory: _extractValue(jsonResponse, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stderr: 'HTTP Error \${response.statusCode}: \${response.reasonPhrase}',
          error: response.body,
        );
      }
    } catch (e) {
      return ExecutionResult(
        error: 'Execution failed: \$e',
      );
    }
  }

  String _escapeJsonString(String input) {
    if (input.isEmpty) return '';
    final encoded = jsonEncode(input);
    return encoded.substring(1, encoded.length - 1);
  }

  String _extractValue(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return '';
    try {
      final keys = path.split('.');
      dynamic current = json;
      for (final key in keys) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return '';
        }
      }
      return current?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }
}
