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
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
  });
}

class ExecutionService {
  static Future<ExecutionResult> runCode({
    required String code,
    required bool useDefault,
    CompilerPreset? preset,
    String? defaultKey,
  }) async {
    if (useDefault || preset == null) {
      return _runDefaultOneCompiler(code, defaultKey!);
    } else {
      return _runCustomPreset(code, preset);
    }
  }

  static Future<ExecutionResult> _runDefaultOneCompiler(String code, String apiKey) async {
    try {
      final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': '',
          'files': [
            {'name': 'main.dart', 'content': code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          executionTime: '${data['executionTime'] ?? 0} ms',
          memory: '-',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: '',
          error: 'API Error: ${response.statusCode} - ${response.body}',
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: 'Network Error: $e',
        executionTime: '',
        memory: '',
      );
    }
  }

  static Future<ExecutionResult> _runCustomPreset(String code, CompilerPreset preset) async {
    try {
      var uri = Uri.parse(preset.url);

      if (preset.queryParams.isNotEmpty) {
        Map<String, String> qp = {};
        for (var param in preset.queryParams) {
          qp[param.key] = param.value;
        }
        uri = uri.replace(queryParameters: qp);
      }

      Map<String, String> headers = {};
      for (var header in preset.headers) {
        headers[header.key] = header.value;
      }

      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = preset.authValue;
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        String basicAuth = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
        headers['Authorization'] = basicAuth;
      }

      String bodyStr = preset.bodyTemplate;
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1);
      bodyStr = bodyStr.replaceAll('{code}', encodedCode);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        dynamic getValue(Map<String, dynamic> json, String path) {
          if (path.isEmpty) return '';
          List<String> keys = path.split('.');
          dynamic current = json;
          for (String key in keys) {
            if (current is Map && current.containsKey(key)) {
              current = current[key];
            } else {
              return '';
            }
          }
          return current?.toString() ?? '';
        }

        return ExecutionResult(
          stdout: getValue(data, preset.stdoutPath),
          stderr: getValue(data, preset.stderrPath),
          error: getValue(data, preset.errorPath),
          executionTime: getValue(data, preset.executionTimePath),
          memory: getValue(data, preset.memoryPath),
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: '',
          error: 'API Error: ${response.statusCode} - ${response.body}',
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: 'Execution Error: $e',
        executionTime: '',
        memory: '',
      );
    }
  }
}
