import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.time,
    required this.memory,
  });
}

class CompilerService {
  static Future<ExecutionResult> executeDefault(String code, String stdin) async {
    final url = Uri.parse(Constants.oneCompilerUrl);
    final headers = {
      'Content-Type': 'application/json',
      'X-RapidAPI-Key': Constants.oneCompilerApiKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
    };
    final body = jsonEncode({
      "language": "dart",
      "stdin": stdin,
      "files": [
        {
          "name": "main.dart",
          "content": code
        }
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          time: data['executionTime']?.toString() ?? '0',
          memory: 'N/A', // OneCompiler might not return memory explicitly in all cases
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: \${response.statusCode}',
          error: response.body,
          time: '0',
          memory: '0',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        time: '0',
        memory: '0',
      );
    }
  }

  static Future<ExecutionResult> executeCustom(CompilerPreset preset, String code, String stdin) async {
    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    Map<String, String> requestHeaders = Map.from(preset.headers);
    if (!requestHeaders.containsKey('Content-Type')) {
      requestHeaders['Content-Type'] = 'application/json';
    }

    if (preset.authType == 'API-Key Header' && preset.authValue != null) {
      // Assuming user sets the header name in 'headers' and we just append it if not?
      // Actually if Auth is API Key header, we can just let them put it in headers.
      // But if there's a specific auth field:
      // We might need to know the header name. Let's assume Authorization for bearer, and a generic for basic
    } else if (preset.authType == 'Bearer Token' && preset.authValue != null) {
      requestHeaders['Authorization'] = 'Bearer \${preset.authValue}';
    } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
      requestHeaders['Authorization'] = 'Basic \${base64Encode(utf8.encode(preset.authValue!))}';
    } else if (preset.authType == 'Query Param' && preset.authValue != null) {
      // It should be in queryParams if they used the table, but if not we can't easily guess the key.
    }

    // Process body template
    // We want to replace {code} and {stdin} while keeping valid JSON.
    // To safely inject code into a JSON string template, we should encode the code to handle quotes/newlines.
    String safeCode = jsonEncode(code);
    safeCode = safeCode.substring(1, safeCode.length - 1); // remove surrounding quotes

    String safeStdin = jsonEncode(stdin);
    safeStdin = safeStdin.substring(1, safeStdin.length - 1);

    String body = preset.bodyTemplate
        .replaceAll('{code}', safeCode)
        .replaceAll('{stdin}', safeStdin)
        .replaceAll('{language}', 'dart');

    try {
      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: body);
      } else {
        response = await http.post(uri, headers: requestHeaders, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractPath(data, preset.responseMapping.stdoutPath)?.toString() ?? '',
          stderr: _extractPath(data, preset.responseMapping.stderrPath)?.toString() ?? '',
          error: _extractPath(data, preset.responseMapping.errorPath)?.toString() ?? '',
          time: _extractPath(data, preset.responseMapping.executionTimePath)?.toString() ?? '0',
          memory: _extractPath(data, preset.responseMapping.memoryPath)?.toString() ?? '0',
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: \${response.statusCode}',
          error: response.body,
          time: '0',
          memory: '0',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        time: '0',
        memory: '0',
      );
    }
  }

  static dynamic _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
