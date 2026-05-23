import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  CompilerResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class CompilerService {
  static Future<CompilerResult> execute({
    required CompilerPreset preset,
    required String code,
    required String stdin,
  }) async {
    try {
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty
            ? {for (var e in preset.queryParams) e['key'].toString(): e['value'].toString()}
            : null,
      );

      final headers = <String, String>{};
      for (var e in preset.headers) {
        headers[e['key'].toString()] = e['value'].toString();
      }

      if (preset.authType == 'API-Key Header') {
        // Assume API key is already in headers or add it if known key
        // For OneCompiler it is already in the headers.
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      String bodyStr = preset.bodyTemplate;
      // safely replace placeholders. Need to format code correctly for JSON string.
      // jsonEncode adds quotes, so strip them
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1);

      String encodedStdin = jsonEncode(stdin);
      encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      bodyStr = bodyStr.replaceAll('{code}', encodedCode);
      bodyStr = bodyStr.replaceAll('{stdin}', encodedStdin);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        return CompilerResult(
          stdout: _extractPath(data, preset.stdoutPath),
          stderr: _extractPath(data, preset.stderrPath),
          error: _extractPath(data, preset.errorPath),
          executionTime: _extractPath(data, preset.executionTimePath),
          memory: _extractPath(data, preset.memoryPath),
        );
      } else {
        return CompilerResult(
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return CompilerResult(error: e.toString());
    }
  }

  static String _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
    try {
      final parts = path.split('.');
      dynamic current = data;
      for (var part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return '';
        }
      }
      return current?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}
