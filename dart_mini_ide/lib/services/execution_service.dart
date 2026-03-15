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

class ExecutionService {
  Future<ExecutionResult> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    try {
      final uri = Uri.parse(preset.endpointUrl);
      final finalUri = preset.queryParams.isNotEmpty
          ? uri.replace(queryParameters: preset.queryParams)
          : uri;

      final Map<String, String> headers = Map.from(preset.headers);

      // Handle simple auth type headers if necessary (Bearer, Basic, API-Key)
      if (preset.authType == 'Bearer Token') {
        if (!headers.containsKey('Authorization')) {
          headers['Authorization'] = 'Bearer YOUR_TOKEN_HERE';
        }
      } else if (preset.authType == 'API-Key Header') {
        // Usually already defined in headers by user, fallback logic not strictly needed
      }

      String requestBody = preset.requestBodyTemplate;

      // JSON encode the code and strip the surrounding quotes to embed it in JSON string safely
      final encodedCode = jsonEncode(code);
      final safeCode = encodedCode.substring(1, encodedCode.length - 1);

      // JSON encode the stdin
      final encodedStdin = jsonEncode(stdin);
      final safeStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      requestBody = requestBody.replaceAll('{code}', '"\$safeCode"');
      requestBody = requestBody.replaceAll('{stdin}', safeStdin); // Assuming template uses "{stdin}"

      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(
          finalUri,
          headers: headers,
          body: requestBody,
        );
      } else if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(finalUri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: requestBody);
      } else {
        throw Exception('Unsupported HTTP method: \${preset.httpMethod}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return _parseResponse(jsonResponse, preset);
      } else {
        return ExecutionResult(
          error: 'HTTP Error \${response.statusCode}: \${response.body}',
        );
      }
    } catch (e) {
      return ExecutionResult(error: 'Execution Exception: \$e');
    }
  }

  ExecutionResult _parseResponse(Map<String, dynamic> response, CompilerPreset preset) {
    String extractValue(String path) {
      if (path.isEmpty) return '';
      final parts = path.split('.');
      dynamic current = response;
      for (final part in parts) {
        if (current is Map && current.containsKey(part)) {
          current = current[part];
        } else {
          return '';
        }
      }
      return current?.toString() ?? '';
    }

    return ExecutionResult(
      stdout: extractValue(preset.stdoutPath),
      stderr: extractValue(preset.stderrPath),
      error: extractValue(preset.errorPath),
      executionTime: extractValue(preset.executionTimePath),
      memory: extractValue(preset.memoryPath),
    );
  }
}
