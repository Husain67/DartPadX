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
  static Future<ExecutionResult> executeDefaultOneCompiler(String code) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    const apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };

    final body = jsonEncode({
      'language': 'dart',
      'stdin': '',
      'files': [
        {'name': 'main.dart', 'content': code}
      ]
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      final json = jsonDecode(response.body);

      return ExecutionResult(
        stdout: json['stdout'] ?? '',
        stderr: json['stderr'] ?? '',
        error: json['exception'] ?? '',
        executionTime: json['executionTime']?.toString() ?? '',
        memory: '', // OneCompiler API might not provide memory directly in the same way
      );
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  static Future<ExecutionResult> executeCustomPreset(String code, CompilerPreset preset) async {
    try {
      Uri uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      Map<String, String> finalHeaders = Map.from(preset.headers);
      if (preset.authType == 'API-Key Header' && finalHeaders.containsKey('Authorization')) {
        // Assume key is already in headers
      } else if (preset.authType == 'Bearer Token' && finalHeaders.containsKey('Authorization')) {
        // Bearer setup is usually handled in the UI when editing the preset headers
      } else if (preset.authType == 'Basic Auth' && finalHeaders.containsKey('Authorization')) {
        final authVal = finalHeaders['Authorization'] ?? '';
        final encoded = base64Encode(utf8.encode(authVal));
        finalHeaders['Authorization'] = 'Basic $encoded';
      }

      String requestBody = preset.requestBodyTemplate;
      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      requestBody = requestBody.replaceAll('{code}', escapedCode);
      requestBody = requestBody.replaceAll('{language}', 'dart');
      requestBody = requestBody.replaceAll('{stdin}', ''); // Add stdin support later if needed

      http.Response response;

      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: finalHeaders, body: requestBody);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: finalHeaders, body: requestBody);
      } else { // GET
        response = await http.get(uri, headers: finalHeaders);
      }

      final json = jsonDecode(response.body);

      String extractPath(Map<String, dynamic> data, String path) {
        if (path.isEmpty) return '';
        final keys = path.split('.');
        dynamic current = data;
        for (var key in keys) {
          if (current is Map && current.containsKey(key)) {
            current = current[key];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      return ExecutionResult(
        stdout: extractPath(json, preset.responseMapping.stdoutPath),
        stderr: extractPath(json, preset.responseMapping.stderrPath),
        error: extractPath(json, preset.responseMapping.errorPath),
        executionTime: extractPath(json, preset.responseMapping.executionTimePath),
        memory: extractPath(json, preset.responseMapping.memoryPath),
      );
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }
}
