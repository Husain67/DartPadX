import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String? error;
  final String? executionTime;
  final String? memoryUsage;
  final bool isSuccess;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    this.error,
    this.executionTime,
    this.memoryUsage,
    required this.isSuccess,
  });
}

class CompilerService {
  final http.Client _client = http.Client();

  Future<ExecutionResult> executeCode({
    required String code,
    required CompilerPreset preset,
    String? stdin,
  }) async {
    try {
      final startTime = DateTime.now();

      // Parse headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token') {
        // Assume the token is stored in a specific header or config, for now simplistic
        // headers['Authorization'] = 'Bearer ...';
      }

      // Construct request body
      // We need to carefully replace placeholders.
      // Basic JSON string replacement can be fragile. Ideally parse JSON template, inject values, then encode.
      // But for "template" as string, we do string replacement.
      String body = preset.requestBodyTemplate;

      // Escape the code for JSON string usage
      final escapedCode = jsonEncode(code);
      // jsonEncode adds quotes, e.g. "void main()...", so we strip them if the template expects raw string inside quotes
      // BUT, usually template is `{"code": "{code}"}`. If we replace `{code}` with `"..."`, we get `{"code": ""...""}`.
      // So we need the content of the json encoded string.
      final codeContent = escapedCode.substring(1, escapedCode.length - 1);

      final escapedStdin = jsonEncode(stdin ?? '');
      final stdinContent = escapedStdin.substring(1, escapedStdin.length - 1);

      body = body
          .replaceAll('{code}', codeContent)
          .replaceAll('{stdin}', stdinContent)
          .replaceAll('{language}', 'dart');

      // Construct URI
      var uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      http.Response response;
      switch (preset.httpMethod.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'PUT':
          response = await _client.put(uri, headers: headers, body: body);
          break;
        case 'POST':
        default:
          response = await _client.post(uri, headers: headers, body: body);
          break;
      }

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Extract fields using dot notation logic
        final stdout = _extractValue(jsonResponse, preset.responseStdoutPath);
        final stderr = _extractValue(jsonResponse, preset.responseStderrPath);
        final error = _extractValue(jsonResponse, preset.responseErrorPath);
        final time = _extractValue(jsonResponse, preset.responseExecutionTimePath);
        final memory = _extractValue(jsonResponse, preset.responseMemoryPath);

        return ExecutionResult(
          stdout: stdout?.toString() ?? '',
          stderr: stderr?.toString() ?? '',
          error: error?.toString(),
          executionTime: time?.toString() ?? '\${duration.inMilliseconds}ms',
          memoryUsage: memory?.toString(),
          isSuccess: true,
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error \${response.statusCode}: \${response.body}',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Exception: \$e',
        isSuccess: false,
      );
    }
  }

  dynamic _extractValue(dynamic data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null; // Key not found
      }
    }
    return current;
  }
}
