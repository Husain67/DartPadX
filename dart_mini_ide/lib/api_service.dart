import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class ApiService {
  static const String _defaultOneCompilerKey = String.fromEnvironment(
    'ONECOMPILER_KEY',
    defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
  );

  Future<ExecutionResult> executeDefault(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
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
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExecutionResult(
        stdout: data['stdout']?.toString() ?? '',
        stderr: data['stderr']?.toString() ?? data['exception']?.toString() ?? '',
        executionTime: data['executionTime']?.toString() ?? '',
        memory: '',
      );
    } else {
      throw Exception('Failed to execute code: \${response.statusCode} - \${response.body}');
    }
  }

  Future<ExecutionResult> executeCustom(CompilerPreset preset, String code, String stdin) async {
    if (preset.endpointUrl.isEmpty || !preset.endpointUrl.startsWith('http')) {
      throw Exception('Invalid endpoint URL.');
    }

    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    final Map<String, String> requestHeaders = Map.from(preset.headers);
    if (preset.authType == 'Bearer Token' && requestHeaders.containsKey('Authorization')) {
       // Typically handled by user adding it to headers, but can be explicit
    }

    String bodyStr = preset.bodyTemplate;
    if (bodyStr.isNotEmpty) {
      final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

      bodyStr = bodyStr.replaceAll('{code}', '"$safeCode"');
      bodyStr = bodyStr.replaceAll('{stdin}', safeStdin);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
    }

    http.Response response;
    try {
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: requestHeaders, body: bodyStr.isNotEmpty ? bodyStr : null);
      } else if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: bodyStr.isNotEmpty ? bodyStr : null);
      } else {
        throw Exception('Unsupported HTTP Method');
      }
    } catch (e) {
      throw Exception('Network error: \$e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: _extractValue(data, preset.stdoutPath)?.toString() ?? '',
          stderr: _extractValue(data, preset.stderrPath)?.toString() ?? _extractValue(data, preset.errorPath)?.toString() ?? '',
          executionTime: _extractValue(data, preset.executionTimePath)?.toString() ?? '',
          memory: _extractValue(data, preset.memoryPath)?.toString() ?? '',
        );
      } catch (e) {
        // If not JSON, return raw body as stdout
        return ExecutionResult(stdout: response.body);
      }
    } else {
       throw Exception('API Error: \${response.statusCode} - \${response.body}');
    }
  }

  dynamic _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}
