import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResponse {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String error;

  ExecutionResponse({
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.error = '',
  });

  @override
  String toString() => 'Stdout: $stdout, Stderr: $stderr, Time: $executionTime, Memory: $memory, Error: $error';
}

class ExecutionService {
  // Default OneCompiler configuration
  static const String oneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run'; // Using RapidAPI endpoint or similar? Or direct?
  // User provided: "Default: OneCompiler API (use key oc_...)"
  // The key format "oc_..." usually implies direct OneCompiler usage.
  // OneCompiler API usually requires `files` array.

  // Let's assume a generic run function that takes url and key.
  // Since I don't have the exact docs for "oc_" keys, I will implement a robust method that tries standard JSON structure.

  static const String _defaultUrl = 'https://onecompiler.com/api/v1/run'; // Common endpoint

  Future<ExecutionResponse> runOneCompiler(String code, String stdin) async {
    const String apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

    try {
      final response = await http.post(
        Uri.parse(_defaultUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "language": "dart",
          "stdin": stdin,
          "files": [
            {"name": "main.dart", "content": code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResponse(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '', // OneCompiler sometimes puts errors in exception
          executionTime: data['executionTime']?.toString() ?? '',
          memory: data['memory']?.toString() ?? '',
          error: data['error'] ?? '',
        );
      } else {
         // Fallback or detailed error
        return ExecutionResponse(error: 'OneCompiler Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      return ExecutionResponse(error: 'Network Exception: $e');
    }
  }

  Future<ExecutionResponse> runCustomPreset(CompilerPreset preset, String code, String stdin) async {
    try {
      // 1. Prepare Headers
      final Map<String, String> headers = Map.from(preset.headers);
      if (preset.authType == 'Bearer Token') {
        // Assuming user puts token in a specific place or we might need an Auth field in preset.
        // For now, relying on headers map.
      }

      // 2. Prepare Query Params
      final Uri uri = Uri.parse(preset.url).replace(queryParameters: preset.queryParams);

      // 3. Prepare Body
      String body = preset.bodyTemplate
          .replaceAll('{code}', _escapeJsonString(code))
          .replaceAll('{stdin}', _escapeJsonString(stdin))
          .replaceAll('{language}', 'dart'); // hardcoded for now or from preset if needed

      // 4. Send Request
      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        return ExecutionResponse(error: 'Unsupported method: ${preset.method}');
      }

      // 5. Parse Response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResponse(
          stdout: _getValueByPath(data, preset.responseMapping['stdout']),
          stderr: _getValueByPath(data, preset.responseMapping['stderr']),
          executionTime: _getValueByPath(data, preset.responseMapping['executionTime']),
          memory: _getValueByPath(data, preset.responseMapping['memory']),
          error: _getValueByPath(data, preset.responseMapping['error']),
        );
      } else {
        return ExecutionResponse(error: 'API Error (${response.statusCode}): ${response.body}');
      }

    } catch (e) {
      return ExecutionResponse(error: 'Custom API Exception: $e');
    }
  }

  String _escapeJsonString(String str) {
    return str.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t');
  }

  String _getValueByPath(dynamic data, String? path) {
    if (path == null || path.isEmpty) return '';
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}
