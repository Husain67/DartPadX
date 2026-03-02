import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.time,
    required this.memory,
  });
}

class CompilerService {
  static const String _defaultOneCompilerKey =
      String.fromEnvironment('ONECOMPILER_KEY', defaultValue: '');

  Future<ExecutionResult> executeCode(String code, CompilerPreset? preset, {String stdin = ''}) async {
    if (preset == null) {
      return _executeOneCompiler(code, stdin);
    }
    return _executeCustomPreset(code, stdin, preset);
  }

  Future<ExecutionResult> _executeOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': _defaultOneCompilerKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };

    final body = jsonEncode({
      'language': 'dart',
      'stdin': stdin,
      'files': [
        {
          'name': 'main.dart',
          'content': code,
        }
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '',
          time: '${data['executionTime'] ?? 0} ms',
          memory: '',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP ${response.statusCode}: ${response.body}',
          time: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Error: $e',
        time: '',
        memory: '',
      );
    }
  }

  Future<ExecutionResult> _executeCustomPreset(String code, String stdin, CompilerPreset preset) async {
    try {
      var uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer ${headers['Authorization']}';
      } else if (preset.authType == 'Basic Auth' && headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(headers['Authorization']!))}';
      }

      String body = preset.requestBodyTemplate;
      // Prevent JSON formatting issues
      final encodedCode = jsonEncode(code);
      final safeCode = encodedCode.substring(1, encodedCode.length - 1);

      final encodedStdin = jsonEncode(stdin);
      final safeStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      body = body.replaceAll('{code}', safeCode)
                 .replaceAll('{language}', 'dart')
                 .replaceAll('{stdin}', safeStdin);

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported HTTP Method');
      }

      final responseBody = response.body;
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (e) {
        return ExecutionResult(
          stdout: responseBody,
          stderr: 'Failed to parse JSON response. Status: ${response.statusCode}',
          time: '',
          memory: '',
        );
      }

      return ExecutionResult(
        stdout: _resolvePath(data, preset.stdoutPath),
        stderr: _resolvePath(data, preset.stderrPath) + (_resolvePath(data, preset.errorPath).isNotEmpty ? '\n${_resolvePath(data, preset.errorPath)}' : ''),
        time: _resolvePath(data, preset.executionTimePath),
        memory: _resolvePath(data, preset.memoryPath),
      );

    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Execution Error: $e',
        time: '',
        memory: '',
      );
    }
  }

  String _resolvePath(dynamic data, String path) {
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
