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
  static const String _defaultOneCompilerKey = String.fromEnvironment('ONECOMPILER_API_KEY');

  Future<ExecutionResult> executeCode({
    required String code,
    required String stdin,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    if (useDefault || preset == null) {
      return _executeWithOneCompiler(code, stdin);
    } else {
      return _executeWithPreset(code, stdin, preset);
    }
  }

  Future<ExecutionResult> _executeWithOneCompiler(String code, String stdin) async {
    const endpoint = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final apiKey = _defaultOneCompilerKey.isNotEmpty
        ? _defaultOneCompilerKey
        : 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'; // Fallback per instructions

    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };

    final body = jsonEncode({
      'language': 'dart',
      'stdin': stdin,
      'files': [
        {'name': 'main.dart', 'content': code}
      ],
    });

    try {
      final response = await http.post(Uri.parse(endpoint), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '',
          executionTime: '${data['executionTime'] ?? 0} ms',
          memory: '',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Error: $e',
        executionTime: '',
        memory: '',
      );
    }
  }

  Future<ExecutionResult> _executeWithPreset(String code, String stdin, CompilerPreset preset) async {
    try {
      // Build Headers
      final Map<String, String> requestHeaders = Map.from(preset.headers);
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
         // This assumes the user adds the specific key name in headers if needed,
         // but a simple standard is Authorization or x-api-key based on preset.
         // Let's rely on user adding it to the headers table, but we will add Authorization for Bearer/Basic.
      }
      if (preset.authType == 'Bearer Token') {
        requestHeaders['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
         requestHeaders['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      // Build URI with query params
      var uri = Uri.parse(preset.endpoint);
      final queryParams = Map<String, String>.from(preset.queryParams);
      if (preset.authType == 'Query Param') {
        // Assume format key=value
        final parts = preset.authValue.split('=');
        if (parts.length == 2) {
          queryParams[parts[0]] = parts[1];
        }
      }
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Build Body
      var requestBody = preset.bodyTemplate;
      // Note: we use string replace for placeholders. Since it's JSON, encode values properly.
      String jsonCode = jsonEncode(code);
      String jsonStdin = jsonEncode(stdin);
      // Remove surrounding quotes from jsonEncode
      jsonCode = jsonCode.substring(1, jsonCode.length - 1);
      jsonStdin = jsonStdin.substring(1, jsonStdin.length - 1);

      requestBody = requestBody.replaceAll('{code}', jsonCode);
      requestBody = requestBody.replaceAll('{stdin}', jsonStdin);
      requestBody = requestBody.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: requestHeaders, body: requestBody);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: requestBody);
      } else {
        response = await http.get(uri, headers: requestHeaders);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractValue(data, preset.stdoutPath),
          stderr: _extractValue(data, preset.stderrPath) + _extractValue(data, preset.errorPath),
          executionTime: _extractValue(data, preset.executionTimePath),
          memory: _extractValue(data, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Error executing custom preset: $e',
        executionTime: '',
        memory: '',
      );
    }
  }

  String _extractValue(dynamic data, String path) {
    if (path.isEmpty) return '';
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
  }
}
