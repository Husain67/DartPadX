import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerOutput {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final String rawResponse;

  CompilerOutput({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
    required this.rawResponse,
  });
}

class CompilerService {
  static Future<CompilerOutput> executeCode({
    required String code,
    required String stdin,
    required String filename,
    required CompilerPreset preset,
  }) async {
    try {
      // 1. Prepare Headers
      final Map<String, String> headers = Map.from(preset.headers);
      if (preset.authType == 'Bearer Token' && preset.authToken != null) {
        headers['Authorization'] = 'Bearer ${preset.authToken}';
      } else if (preset.authType == 'Basic Auth' && preset.authToken != null) {
        final bytes = utf8.encode(preset.authToken!);
        final base64Str = base64.encode(bytes);
        headers['Authorization'] = 'Basic $base64Str';
      }

      // 2. Prepare Query Params
      final Map<String, String> queryParams = Map.from(preset.queryParams);
      if (preset.authType == 'Query Param' && preset.authToken != null) {
        queryParams['api_key'] = preset.authToken!; // Basic assumption, user can edit this in UI
      }

      var uri = Uri.parse(preset.endpointUrl);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // 3. Prepare Body
      String body = preset.requestBodyTemplate;

      // Escape for JSON string representation
      final escapedCode = _escapeJson(code);
      final escapedStdin = _escapeJson(stdin);
      final escapedFilename = _escapeJson(filename);

      body = body.replaceAll('{code}', escapedCode);
      body = body.replaceAll('{stdin}', escapedStdin);
      body = body.replaceAll('{filename}', escapedFilename);
      body = body.replaceAll('{language}', 'dart');

      // 4. Make Request
      http.Response response;
      final method = preset.httpMethod.toUpperCase();

      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      // 5. Parse Response
      final rawResponse = response.body;
      Map<String, dynamic> jsonResponse = {};

      try {
        jsonResponse = jsonDecode(rawResponse) as Map<String, dynamic>;
      } catch (e) {
        return CompilerOutput(
          stdout: '',
          stderr: 'Failed to parse API response as JSON.',
          error: e.toString(),
          executionTime: '',
          memory: '',
          rawResponse: rawResponse,
        );
      }

      return CompilerOutput(
        stdout: _getValueFromPath(jsonResponse, preset.stdoutPath),
        stderr: _getValueFromPath(jsonResponse, preset.stderrPath),
        error: _getValueFromPath(jsonResponse, preset.errorPath),
        executionTime: _getValueFromPath(jsonResponse, preset.executionTimePath),
        memory: _getValueFromPath(jsonResponse, preset.memoryPath),
        rawResponse: rawResponse,
      );

    } catch (e) {
      return CompilerOutput(
        stdout: '',
        stderr: 'Execution Exception: $e',
        error: e.toString(),
        executionTime: '',
        memory: '',
        rawResponse: '',
      );
    }
  }

  static String _escapeJson(String input) {
    // A quick hack to escape newlines and quotes to safely inject into custom JSON template
    return input.replaceAll('\\', '\\\\')
                .replaceAll('"', '\\"')
                .replaceAll('\n', '\\n')
                .replaceAll('\r', '\\r')
                .replaceAll('\t', '\\t');
  }

  static String _getValueFromPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return '';
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
  }
}
