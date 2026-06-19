import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String output;
  final String error;
  final String time;
  final String memory;

  ExecutionResult({
    required this.output,
    required this.error,
    required this.time,
    required this.memory,
  });
}

class ExecutionService {
  static Future<ExecutionResult> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    try {
      final endpoint = preset.endpointUrl;
      final method = preset.httpMethod.toUpperCase();

      // Prepare Headers
      Map<String, String> requestHeaders = Map.from(preset.headers);

      // Prepare Auth
      if (preset.authType == 'Bearer Token') {
        final token = requestHeaders['Authorization'] ?? '';
        requestHeaders['Authorization'] = 'Bearer \$token';
      } else if (preset.authType == 'Basic Auth') {
        final username = requestHeaders['username'] ?? '';
        final password = requestHeaders['password'] ?? '';
        final encoded = base64Encode(utf8.encode('\$username:\$password'));
        requestHeaders['Authorization'] = 'Basic \$encoded';
        requestHeaders.remove('username');
        requestHeaders.remove('password');
      }

      // Prepare Body
      String requestBody = preset.requestBodyTemplate
          .replaceAll('{code}', _escapeJsonString(code))
          .replaceAll('{stdin}', _escapeJsonString(stdin))
          .replaceAll('{language}', 'dart');

      // Prepare Query Params
      Uri uri = Uri.parse(endpoint);
      if (preset.queryParams.isNotEmpty) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams.addAll(preset.queryParams);
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;

      if (method == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: requestBody);
      } else {
        // Default to POST
        response = await http.post(uri, headers: requestHeaders, body: requestBody);
      }

      final isJson = response.headers['content-type']?.contains('application/json') ?? true;

      if (!isJson) {
         return ExecutionResult(
            output: response.statusCode == 200 ? response.body : '',
            error: response.statusCode != 200 ? 'HTTP \${response.statusCode}: \${response.body}' : '',
            time: '',
            memory: '',
          );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      final stdout = _extractValue(responseData, preset.stdoutPath) ?? '';
      final stderr = _extractValue(responseData, preset.stderrPath) ?? '';
      final error = _extractValue(responseData, preset.errorPath) ?? '';
      final time = _extractValue(responseData, preset.executionTimePath) ?? '';
      final memory = _extractValue(responseData, preset.memoryPath) ?? '';

      return ExecutionResult(
        output: stdout,
        error: stderr.isNotEmpty ? stderr : error,
        time: time,
        memory: memory,
      );
    } catch (e) {
      return ExecutionResult(
        output: '',
        error: 'Execution failed: \$e',
        time: '',
        memory: '',
      );
    }
  }

  static String _escapeJsonString(String input) {
    return input.replaceAll('\\\\', '\\\\\\\\')
                .replaceAll('"', '\\\\"')
                .replaceAll('\n', '\\n')
                .replaceAll('\r', '\\r')
                .replaceAll('\t', '\\t');
  }

  static String? _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;

    final keys = path.split('.');
    dynamic current = data;

    for (String key in keys) {
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
