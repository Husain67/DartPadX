import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final bool isError;
  final String rawResponse;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
    this.isError = false,
    this.rawResponse = '',
  });
}

class ApiService {
  static const String _defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  Future<ExecutionResult> executeOneCompiler(String code) async {
    final String key = const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: _defaultOneCompilerKey);
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': key,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
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

      final body = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return ExecutionResult(
          stdout: '',
          stderr: body['message'] ?? 'Unknown Error: ${response.statusCode}',
          executionTime: '-',
          memory: '-',
          isError: true,
          rawResponse: response.body,
        );
      }

      return ExecutionResult(
        stdout: body['stdout'] ?? '',
        stderr: body['stderr'] ?? body['exception'] ?? '',
        executionTime: body['executionTime']?.toString() ?? '-',
        memory: '-',
        isError: (body['stderr'] != null && body['stderr'].isNotEmpty) || (body['exception'] != null && body['exception'].isNotEmpty),
        rawResponse: response.body,
      );
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: e.toString(),
        executionTime: '-',
        memory: '-',
        isError: true,
        rawResponse: e.toString(),
      );
    }
  }

  Future<ExecutionResult> executeCustomAPI(String code, CompilerPreset preset) async {
    try {
      // Build Headers
      Map<String, String> headers = {...preset.dynamicHeaders};
      if (preset.authType == 'API-Key Header') {
        final split = preset.authValue.split(':');
        if (split.length == 2) {
          headers[split[0].trim()] = split[1].trim();
        }
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      // Build Query Params
      Map<String, String> queryParams = {...preset.dynamicQueryParams};
      if (preset.authType == 'Query Param') {
        final split = preset.authValue.split('=');
        if (split.length == 2) {
          queryParams[split[0].trim()] = split[1].trim();
        }
      }

      // Build URL
      Uri url = Uri.parse(preset.endpointUrl);
      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      // Build Body
      String bodyStr = preset.requestBodyTemplate;

      // Smart JSON replace to prevent breaking format
      final safeCode = jsonEncode(code);
      final rawSafeCode = safeCode.substring(1, safeCode.length - 1); // remove outer quotes

      bodyStr = bodyStr.replaceAll('{code}', rawSafeCode);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;

      if (preset.httpMethod == 'POST') {
        response = await http.post(url, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(url, headers: headers, body: bodyStr);
      } else {
        response = await http.get(url, headers: headers);
      }

      Map<String, dynamic> responseJson = {};
      try {
        responseJson = jsonDecode(response.body);
      } catch (e) {
        // If response is not JSON
        return ExecutionResult(
          stdout: response.body,
          stderr: '',
          executionTime: '-',
          memory: '-',
          isError: response.statusCode != 200,
          rawResponse: response.body,
        );
      }

      String resolvePath(String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = responseJson;
        for (final part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      final stdout = resolvePath(preset.stdoutPath);
      final stderr = resolvePath(preset.stderrPath);
      final error = resolvePath(preset.errorPath);
      final execTime = resolvePath(preset.executionTimePath);
      final mem = resolvePath(preset.memoryPath);

      final finalError = stderr.isNotEmpty ? stderr : error;

      return ExecutionResult(
        stdout: stdout,
        stderr: finalError,
        executionTime: execTime.isEmpty ? '-' : execTime,
        memory: mem.isEmpty ? '-' : mem,
        isError: finalError.isNotEmpty || response.statusCode != 200,
        rawResponse: response.body,
      );

    } catch (e) {
       return ExecutionResult(
        stdout: '',
        stderr: e.toString(),
        executionTime: '-',
        memory: '-',
        isError: true,
        rawResponse: e.toString(),
      );
    }
  }
}
