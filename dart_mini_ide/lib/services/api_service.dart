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

class ApiService {
  Future<ExecutionResult> executeCode(String code, CompilerPreset preset) async {
    try {
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      final headers = Map<String, String>.from(preset.headers);

      // Basic Authentication logic if specified in preset auth type
      if (preset.authType == 'Basic Auth') {
        // Find credentials in headers or assume format if customized
        // Placeholder implementation for generic Basic Auth mapping
        // In a real advanced app, specific user/pass fields might exist
      }

      String bodyStr = preset.requestBodyTemplate;

      // JSON template replacements
      // Escape code properly for JSON. Very basic replace, real app might use jsonEncode logic
      final String encodedCode = jsonEncode(code);
      final String cleanCode = encodedCode.substring(1, encodedCode.length - 1);

      bodyStr = bodyStr.replaceAll('{code}', cleanCode);
      bodyStr = bodyStr.replaceAll('{stdin}', '');
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{name}', 'main.dart');

      http.Response response;

      switch (preset.httpMethod.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyStr);
          break;
        case 'POST':
        default:
          response = await http.post(uri, headers: headers, body: bodyStr);
          break;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        return ExecutionResult(
          stdout: _extractValue(data, preset.stdoutPath) ?? '',
          stderr: _extractValue(data, preset.stderrPath) ?? '',
          error: _extractValue(data, preset.errorPath) ?? '',
          executionTime: _extractValue(data, preset.executionTimePath)?.toString() ?? '',
          memory: _extractValue(data, preset.memoryPath)?.toString() ?? '',
        );
      } else {
        return ExecutionResult(
          error: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return ExecutionResult(
        error: 'Execution failed: $e',
      );
    }
  }

  dynamic _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
