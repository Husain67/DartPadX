import 'dart:convert';
import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/models/execution_result.dart';
import 'package:http/http.dart' as http;

class ExecutionService {
  final http.Client _client = http.Client();

  Future<ExecutionResult> executeCode({
    required CodeFile file,
    required String stdin,
    CompilerPreset? preset,
  }) async {
    if (preset == null) {
      return _executeOneCompiler(file, stdin);
    } else {
      return _executeCustomPreset(file, stdin, preset);
    }
  }

  Future<ExecutionResult> _executeOneCompiler(CodeFile file, String stdin) async {
    const url = 'https://api.onecompiler.com/v1/run';
    final headers = {
      'Content-Type': 'application/json',
      'X-API-KEY': AppConstants.defaultOneCompilerKey,
    };

    final body = jsonEncode({
      'language': file.language,
      'files': [
        {
          'name': file.name,
          'content': file.content,
        }
      ],
      'stdin': stdin,
    });

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        return ExecutionResult(
          error: 'API Error: ${response.statusCode} ${response.reasonPhrase}',
          isSuccess: false,
        );
      }

      final data = jsonDecode(response.body);

      // Check for API-specific error fields
      if (data['status'] == 'failed' || (data['exception'] != null && data['exception'] != '')) {
         return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? data['error'] ?? 'Unknown error',
          executionTime: '${data['executionTime'] ?? 0}ms',
          memory: '${data['memoryUsed'] ?? 0}KB',
          isSuccess: false,
        );
      }

      return ExecutionResult(
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? '',
        executionTime: '${data['executionTime'] ?? 0}ms',
        memory: '${data['memoryUsed'] ?? 0}KB',
        isSuccess: true,
      );
    } catch (e) {
      return ExecutionResult(
        error: 'Network Error: $e',
        isSuccess: false,
      );
    }
  }

  Future<ExecutionResult> _executeCustomPreset(CodeFile file, String stdin, CompilerPreset preset) async {
    final url = preset.endpoint;

    // Prepare headers
    final headers = Map<String, String>.from(preset.headers);

    // Prepare Query Params
    final uri = Uri.parse(url).replace(queryParameters: preset.queryParams);

    // Prepare Body
    // Simple template replacement
    String bodyStr = preset.requestBodyTemplate;

    // Use jsonEncode to properly escape strings, then remove surrounding quotes
    String escape(String s) {
      final encoded = jsonEncode(s);
      return encoded.substring(1, encoded.length - 1);
    }

    bodyStr = bodyStr.replaceAll('{code}', escape(file.content));
    bodyStr = bodyStr.replaceAll('{language}', escape(file.language));
    bodyStr = bodyStr.replaceAll('{stdin}', escape(stdin));

    try {
      http.Response response;
      if (preset.method == 'POST') {
        response = await _client.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method == 'GET') {
        response = await _client.get(uri, headers: headers);
      } else if (preset.method == 'PUT') {
        response = await _client.put(uri, headers: headers, body: bodyStr);
      } else {
        return ExecutionResult(
          error: 'Unsupported method: ${preset.method}',
          isSuccess: false,
        );
      }

      final data = jsonDecode(response.body);

      // Map response using dot notation
      dynamic getValue(dynamic json, String path) {
        if (path.isEmpty) return null;
        final keys = path.split('.');
        dynamic current = json;
        for (final key in keys) {
          if (current is Map && current.containsKey(key)) {
            current = current[key];
          } else {
            return null;
          }
        }
        return current;
      }

      final stdout = getValue(data, preset.stdoutPath);
      final stderr = getValue(data, preset.stderrPath);
      final error = getValue(data, preset.errorPath);
      final executionTime = getValue(data, preset.executionTimePath);
      final memory = getValue(data, preset.memoryPath);

      return ExecutionResult(
        stdout: stdout?.toString() ?? '',
        stderr: stderr?.toString() ?? '',
        error: error?.toString(),
        executionTime: executionTime?.toString(),
        memory: memory?.toString(),
        isSuccess: error == null && (stderr == null || stderr.toString().isEmpty),
      );

    } catch (e) {
      return ExecutionResult(
        error: 'Execution Error: $e',
        isSuccess: false,
      );
    }
  }
}
