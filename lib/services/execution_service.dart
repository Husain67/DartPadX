import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
  });
}

class ExecutionService {
  static Future<ExecutionResult> executeCode({
    required CompilerPreset preset,
    required String code,
    String stdin = '',
  }) async {
    try {
      final uri = Uri.parse(preset.endpoint);

      // Build Headers
      final Map<String, String> requestHeaders = Map.from(preset.headers);
      if (preset.authType == 'Bearer Token' && requestHeaders.containsKey('Authorization')) {
        // Assume token is in headers map under 'Authorization'
      }

      // Build Body
      String bodyString = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
          .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
          .replaceAll('{language}', 'dart');

      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: bodyString,
        );
      } else if (preset.httpMethod.toUpperCase() == 'GET') {
        // Convert body to query params if GET (rare for compilers, but requested)
        final Map<String, dynamic> bodyJson = jsonDecode(bodyString);
        final getUri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...preset.queryParams,
          ...bodyJson.map((k, v) => MapEntry(k, v.toString())),
        });
        response = await http.get(getUri, headers: requestHeaders);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.httpMethod}');
      }

      final jsonResponse = jsonDecode(response.body);

      // Extract based on dot notation
      String extractedStdout = _extractField(jsonResponse, preset.stdoutPath) ?? '';
      String extractedStderr = _extractField(jsonResponse, preset.stderrPath) ?? '';
      String extractedError = _extractField(jsonResponse, preset.errorPath) ?? '';

      if (extractedStderr.isEmpty && extractedError.isNotEmpty) {
          extractedStderr = extractedError;
      }

      String extractedTime = _extractField(jsonResponse, preset.executionTimePath) ?? '';
      String extractedMemory = _extractField(jsonResponse, preset.memoryPath) ?? '';

      return ExecutionResult(
        stdout: extractedStdout.trim(),
        stderr: extractedStderr.trim(),
        executionTime: extractedTime,
        memory: extractedMemory,
      );
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Execution Error: $e',
        executionTime: '',
        memory: '',
      );
    }
  }

  static String? _extractField(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
