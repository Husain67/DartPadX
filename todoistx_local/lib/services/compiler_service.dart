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

class CompilerService {
  static const String _defaultOneCompilerEndpoint = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  Future<ExecutionResult> executeCode(String code, CompilerPreset preset) async {
    if (preset.isDefaultPreset) {
      return _executeOneCompiler(code);
    } else {
      return _executeCustomPreset(code, preset);
    }
  }

  Future<ExecutionResult> _executeOneCompiler(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_defaultOneCompilerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-key': _defaultOneCompilerKey,
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: json.encode({
          'language': 'dart',
          'stdin': '',
          'files': [
            {
              'name': 'main.dart',
              'content': code,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '',
          executionTime: '${data['executionTime'] ?? 0} ms',
          memory: 'N/A', // OneCompiler API might not provide memory directly in this format
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          executionTime: '-',
          memory: '-',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Exception: $e',
        executionTime: '-',
        memory: '-',
      );
    }
  }

  Future<ExecutionResult> _executeCustomPreset(String code, CompilerPreset preset) async {
    try {
      // Build URI with query params
      var uri = Uri.parse(preset.endpoint);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      // Build Headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header') {
        // Typically passed in headers map directly, but if they want automatic parsing:
        // headers['x-api-key'] = preset.queryParams['api_key'] ?? '';
      } else if (preset.authType == 'Bearer Token') {
        // Find token in headers or params if not explicitly set
        if (!headers.containsKey('Authorization')) {
          headers['Authorization'] = 'Bearer ${preset.headers['Authorization'] ?? ''}';
        }
      } else if (preset.authType == 'Basic Auth') {
        if (!headers.containsKey('Authorization')) {
          final credentials = preset.headers['Authorization'] ?? '';
          final encoded = base64.encode(utf8.encode(credentials));
          headers['Authorization'] = 'Basic $encoded';
        }
      }

      // Build Body
      String bodyStr = preset.requestBodyTemplate;
      // Sanitize code for JSON
      String safeCode = code.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r');
      bodyStr = bodyStr.replaceAll('{code}', safeCode);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body);

        return ExecutionResult(
          stdout: _extractPath(data, preset.stdoutPath) ?? '',
          stderr: _extractPath(data, preset.stderrPath) ?? _extractPath(data, preset.errorPath) ?? '',
          executionTime: _extractPath(data, preset.executionTimePath) ?? '-',
          memory: _extractPath(data, preset.memoryPath) ?? '-',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
          executionTime: '-',
          memory: '-',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Exception: $e',
        executionTime: '-',
        memory: '-',
      );
    }
  }

  String? _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    try {
      final parts = path.split('.');
      dynamic current = data;
      for (final part in parts) {
        if (current is Map<String, dynamic> && current.containsKey(part)) {
          current = current[part];
        } else {
          return null;
        }
      }
      return current?.toString();
    } catch (e) {
      return null;
    }
  }
}
