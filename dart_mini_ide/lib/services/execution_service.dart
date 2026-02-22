import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../models/execution_result.dart';

class ExecutionService {
  static const String oneCompilerUrl = 'https://onecompiler.com/api/code/exec';
  static const String oneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  Future<ExecutionResult> executeOneCompiler(String code, String stdin) async {
    try {
      final response = await http.post(
        Uri.parse(oneCompilerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oneCompilerKey',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': stdin,
          'files': [
            {
              'name': 'main.dart',
              'content': code,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'],
          executionTime: data['executionTime']?.toString(),
          isSuccess: true,
        );
      } else {
        return ExecutionResult(
          error: 'HTTP ${response.statusCode}: ${response.body}',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ExecutionResult(
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  Future<ExecutionResult> executeCustom(
    CompilerPreset preset,
    String code,
    String stdin,
  ) async {
    try {
      // Build URI with query params
      final uri = Uri.parse(preset.endpointUrl).replace(
        queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null,
      );

      // Prepare headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer') {
        // Assuming token is in headers or we prompt?
        // The preset should contain the auth header if it's static.
        // If "Auth Type" is selected, usually it implies adding a specific header.
        // But for this "Super Advanced" system, the user likely adds the header manually in the Dynamic Headers table.
        // We will respect the headers map.
      }
      headers['Content-Type'] = 'application/json';

      // Prepare body
      String body = preset.requestBodyTemplate;
      body = body.replaceAll('{code}', _escapeJsonString(code));
      body = body.replaceAll('{stdin}', _escapeJsonString(stdin));
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.post(uri, headers: headers, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _getValueByPath(data, preset.stdoutPath) ?? '',
          stderr: _getValueByPath(data, preset.stderrPath) ?? '',
          error: _getValueByPath(data, preset.errorPath),
          executionTime: _getValueByPath(data, preset.executionTimePath),
          memory: _getValueByPath(data, preset.memoryPath),
          isSuccess: true,
        );
      } else {
        return ExecutionResult(
          error: 'HTTP ${response.statusCode}: ${response.body}',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ExecutionResult(
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  String _escapeJsonString(String str) {
    final jsonStr = jsonEncode(str);
    // Remove surrounding quotes
    return jsonStr.substring(1, jsonStr.length - 1);
  }

  String? _getValueByPath(dynamic json, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
