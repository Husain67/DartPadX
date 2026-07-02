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
  static const String _defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultRapidApiKey = String.fromEnvironment('RAPIDAPI_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

  static Future<ExecutionResult> executeWithOneCompiler(String code, String stdin) async {
    final response = await http.post(
      Uri.parse(_defaultOneCompilerUrl),
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': _defaultRapidApiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [
          {
            "name": "index.dart",
            "content": code
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExecutionResult(
        stdout: data['stdout']?.toString() ?? '',
        stderr: data['stderr']?.toString() ?? (data['exception']?.toString() ?? ''),
        executionTime: data['executionTime']?.toString() ?? '',
        memory: '',
      );
    } else {
      throw Exception('OneCompiler execution failed: ${response.body}');
    }
  }

  static Future<ExecutionResult> executeWithPreset(CompilerPreset preset, String code, String stdin) async {
    String bodyStr = preset.requestBodyTemplate
        .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
        .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
        .replaceAll('{language}', 'dart');

    Uri uri = Uri.parse(preset.endpointUrl);

    if (preset.authType == 'Query Param') {
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams.addAll(preset.queryParams);
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.queryParams['token'] ?? ''}';
    } else if (preset.authType == 'API-Key Header') {
      headers.addAll(preset.queryParams);
    }

    http.Response response;

    try {
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      String extract(String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = data;
        for (final part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      String stdout = extract(preset.responseMapping.stdoutPath);
      String stderr = extract(preset.responseMapping.stderrPath);
      if (stderr.isEmpty && preset.responseMapping.errorPath.isNotEmpty) {
        stderr = extract(preset.responseMapping.errorPath);
      }
      String executionTime = extract(preset.responseMapping.executionTimePath);
      String memory = extract(preset.responseMapping.memoryPath);

      return ExecutionResult(
        stdout: stdout,
        stderr: stderr,
        executionTime: executionTime,
        memory: memory,
      );
    } else {
      throw Exception('API error (${response.statusCode}): ${response.body}');
    }
  }
}
