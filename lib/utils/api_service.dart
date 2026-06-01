import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/preset_model.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final String rawResponse;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
    required this.rawResponse,
  });

  factory ExecutionResult.empty() {
    return ExecutionResult(
      stdout: '',
      stderr: '',
      error: '',
      executionTime: '',
      memory: '',
      rawResponse: '',
    );
  }
}

class ApiService {
  static const String _defaultOneCompilerEndpoint = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultOneCompilerKey = String.fromEnvironment('OC_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

  static Future<ExecutionResult> executeDefault(String code, String stdin) async {
    final startTime = DateTime.now();
    try {
      final response = await http.post(
        Uri.parse(_defaultOneCompilerEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': _defaultOneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': stdin,
          'files': [
            {'name': 'main.dart', 'content': code}
          ]
        }),
      );

      final endTime = DateTime.now();
      final executionTime = '${endTime.difference(startTime).inMilliseconds} ms';

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          executionTime: data['executionTime']?.toString() ?? executionTime,
          memory: '',
          rawResponse: response.body,
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'API Error: ${response.statusCode}',
          error: response.body,
          executionTime: executionTime,
          memory: '',
          rawResponse: response.body,
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
        rawResponse: '',
      );
    }
  }

  static Future<ExecutionResult> executeWithPreset(PresetModel preset, String code, String stdin) async {
    final startTime = DateTime.now();
    try {
      // Setup URL
      var urlStr = preset.endpointUrl;

      // Inject query params
      if (preset.queryParams.isNotEmpty) {
        final uri = Uri.parse(urlStr);
        urlStr = uri.replace(queryParameters: preset.queryParams).toString();
      }

      // Prepare headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token') {
         // Should ideally extract token from another field, but for simplicity we rely on manual header injection in settings
      } else if (preset.authType == 'API-Key Header') {
        // Similar assumption
      }

      if (!headers.containsKey('Content-Type')) {
        headers['Content-Type'] = 'application/json';
      }

      // Prepare body
      String body = preset.requestBodyTemplate;
      body = body.replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''));
      body = body.replaceAll('{stdin}', jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), ''));
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      final uri = Uri.parse(urlStr);

      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      final endTime = DateTime.now();
      final execTimeFallback = '${endTime.difference(startTime).inMilliseconds} ms';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String extractPath(String path, dynamic json) {
          if (path.isEmpty) return '';
          try {
            final parts = path.split('.');
            dynamic current = json;
            for (final p in parts) {
              if (current is Map && current.containsKey(p)) {
                current = current[p];
              } else {
                return '';
              }
            }
            return current?.toString() ?? '';
          } catch (_) {
            return '';
          }
        }

        return ExecutionResult(
          stdout: extractPath(preset.stdoutPath, data),
          stderr: extractPath(preset.stderrPath, data),
          error: extractPath(preset.errorPath, data),
          executionTime: extractPath(preset.executionTimePath, data).isNotEmpty ? extractPath(preset.executionTimePath, data) : execTimeFallback,
          memory: extractPath(preset.memoryPath, data),
          rawResponse: response.body,
        );
      } else {
         return ExecutionResult(
          stdout: '',
          stderr: 'API Error: ${response.statusCode}',
          error: response.body,
          executionTime: execTimeFallback,
          memory: '',
          rawResponse: response.body,
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
        rawResponse: '',
      );
    }
  }
}
