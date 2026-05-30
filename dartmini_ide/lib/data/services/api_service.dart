import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../../core/constants/app_constants.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final Map<String, dynamic> rawResponse;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    required this.rawResponse,
  });
}

class ApiService {
  static Future<ExecutionResult> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    try {
      final uri = Uri.parse(preset.endpoint);
      final headers = Map<String, String>.from(preset.headers);

      // Handle Auth
      if (preset.authType == 'Header' && preset.authValue.isNotEmpty) {
        final parts = preset.authValue.split(':');
        if (parts.length >= 2) {
          headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      } else if (preset.authType == 'Bearer' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      }

      // Handle Body Template
      String bodyStr = '';
      if (preset.bodyTemplate.isNotEmpty) {
        bodyStr = preset.bodyTemplate;

        final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
        final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

        bodyStr = bodyStr.replaceAll('{code}', safeCode);
        bodyStr = bodyStr.replaceAll('{stdin}', safeStdin);
        bodyStr = bodyStr.replaceAll('{language}', 'dart');
      }

      if (!headers.containsKey('Content-Type') && bodyStr.isNotEmpty) {
        headers['Content-Type'] = 'application/json';
      }

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        throw Exception('Unsupported HTTP method: ${preset.method}');
      }

      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (e) {
        return ExecutionResult(
          error: 'Failed to parse JSON response. Status: ${response.statusCode}\nBody:\n${response.body}',
          rawResponse: {'raw': response.body},
        );
      }

      String extractPath(Map<String, dynamic> json, String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = json;
        for (final part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      return ExecutionResult(
        stdout: extractPath(jsonResponse, preset.responseStdoutPath),
        stderr: extractPath(jsonResponse, preset.responseStderrPath),
        error: extractPath(jsonResponse, preset.responseErrorPath),
        executionTime: extractPath(jsonResponse, preset.responseTimePath),
        memory: extractPath(jsonResponse, preset.responseMemoryPath),
        rawResponse: jsonResponse,
      );
    } catch (e) {
      return ExecutionResult(
        error: e.toString(),
        rawResponse: {},
      );
    }
  }

  static Future<ExecutionResult> executeOneCompiler(String code, String stdin) async {
    try {
      final uri = Uri.parse(AppConstants.oneCompilerEndpoint);
      final headers = {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': AppConstants.oneCompilerDefaultKey,
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

      final response = await http.post(uri, headers: headers, body: body);
      final jsonResponse = jsonDecode(response.body);

      return ExecutionResult(
        stdout: jsonResponse['stdout'] ?? '',
        stderr: jsonResponse['stderr'] ?? '',
        error: jsonResponse['exception'] ?? '',
        executionTime: jsonResponse['executionTime']?.toString() ?? '',
        memory: '',
        rawResponse: jsonResponse,
      );
    } catch (e) {
      return ExecutionResult(error: e.toString(), rawResponse: {});
    }
  }
}
