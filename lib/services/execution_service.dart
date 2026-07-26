import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../data/models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
  });
}

class ExecutionService {
  static Future<ExecutionResult> runCode({
    required String code,
    required bool useDefault,
    CompilerPreset? customPreset,
  }) async {
    try {
      if (useDefault || customPreset == null) {
        return await _runOneCompiler(code);
      } else {
        return await _runCustomPreset(code, customPreset);
      }
    } catch (e) {
      return ExecutionResult(stderr: 'Execution Error: \$e');
    }
  }

  static Future<ExecutionResult> _runOneCompiler(String code) async {
    final response = await http.post(
      Uri.parse(AppConstants.oneCompilerUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': AppConstants.defaultOneCompilerKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": "",
        "files": [
          {"name": "main.dart", "content": code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExecutionResult(
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? data['exception'] ?? '',
        time: (data['executionTime'] ?? '').toString(),
        memory: (data['memory'] ?? '').toString(),
      );
    } else {
      return ExecutionResult(
          stderr: 'HTTP \${response.statusCode}: \${response.body}');
    }
  }

  static Future<ExecutionResult> _runCustomPreset(
      String code, CompilerPreset preset) async {
    // 1. Prepare Headers
    Map<String, String> requestHeaders = {'Content-Type': 'application/json'};
    requestHeaders.addAll(preset.headers);

    if (preset.authType == 'API-Key Header') {
      final parts = preset.authValue.split(':');
      if (parts.length == 2) {
        requestHeaders[parts[0].trim()] = parts[1].trim();
      }
    } else if (preset.authType == 'Bearer Token') {
      requestHeaders['Authorization'] = 'Bearer \${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      requestHeaders['Authorization'] =
          'Basic \${base64Encode(utf8.encode(preset.authValue))}';
    }

    // 2. Prepare URL & Query Params
    var uri = Uri.parse(preset.endpoint);
    Map<String, String> qParams = Map.from(uri.queryParameters);
    qParams.addAll(preset.queryParams);

    if (preset.authType == 'Query Param') {
      final parts = preset.authValue.split('=');
      if (parts.length == 2) {
        qParams[parts[0].trim()] = parts[1].trim();
      }
    }

    if (qParams.isNotEmpty) {
      uri = uri.replace(queryParameters: qParams);
    }

    // 3. Prepare Body
    String bodyStr = preset.bodyTemplate;
    // Replace placeholders. Be careful with json encoding of code containing quotes/newlines.
    // We encode the string and then strip the surrounding quotes to safely inject it into JSON string.
    String safeCode = jsonEncode(code);
    safeCode = safeCode.substring(1, safeCode.length - 1);

    bodyStr = bodyStr.replaceAll('{code}', safeCode);
    bodyStr = bodyStr.replaceAll('{stdin}', '');
    bodyStr = bodyStr.replaceAll('{language}', 'dart');

    http.Response response;

    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(uri, headers: requestHeaders);
    } else {
      response = await http.post(uri, headers: requestHeaders, body: bodyStr);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractValue(data, preset.stdoutPath),
          stderr: _extractValue(data, preset.stderrPath) +
              (_extractValue(data, preset.errorPath)),
          time: _extractValue(data, preset.timePath),
          memory: _extractValue(data, preset.memoryPath),
        );
      } catch (e) {
        return ExecutionResult(stdout: response.body); // Return raw if not JSON
      }
    } else {
      return ExecutionResult(
          stderr: 'HTTP \${response.statusCode}: \${response.body}');
    }
  }

  static String _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
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
