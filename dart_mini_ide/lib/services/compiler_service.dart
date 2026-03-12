import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerResult {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  CompilerResult({
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
  });
}

class CompilerService {
  static const String _defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultOneCompilerKey = String.fromEnvironment(
    'ONECOMPILER_KEY',
    defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
  );

  static Future<CompilerResult> executeCode(
      String code, bool useDefault, CompilerPreset? preset) async {
    try {
      if (useDefault) {
        return await _executeOneCompiler(code);
      } else {
        if (preset == null) {
          throw Exception('No custom preset selected.');
        }
        return await _executeCustomPreset(code, preset);
      }
    } catch (e) {
      return CompilerResult(
        stdout: '',
        stderr: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  static Future<CompilerResult> _executeOneCompiler(String code) async {
    final response = await http.post(
      Uri.parse(_defaultOneCompilerUrl),
      headers: {
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'x-rapidapi-key': _defaultOneCompilerKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": "",
        "files": [
          {
            "name": "main.dart",
            "content": code,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CompilerResult(
        stdout: json['stdout']?.toString() ?? '',
        stderr: json['stderr']?.toString() ?? json['exception']?.toString() ?? '',
        executionTime: json['executionTime']?.toString() ?? '',
        memory: '',
      );
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }

  static Future<CompilerResult> _executeCustomPreset(String code, CompilerPreset preset) async {
    final stopwatch = Stopwatch()..start();

    // Process request body
    String body = preset.requestBodyTemplate;
    final encodedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    body = body.replaceAll('{code}', encodedCode);
    body = body.replaceAll('{language}', 'dart');
    body = body.replaceAll('{stdin}', '');

    // Process headers
    Map<String, String> requestHeaders = Map.from(preset.headers);
    if (preset.authType == AuthType.bearerToken) {
      requestHeaders['Authorization'] = 'Bearer ${preset.queryParams['token'] ?? ''}'; // Simplified
    }

    // Process URI
    Uri uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    http.Response response;
    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: requestHeaders, body: body.isEmpty ? null : body);
    } else {
      response = await http.get(uri, headers: requestHeaders);
    }

    stopwatch.stop();

    String rawResponse = response.body;
    try {
      final json = jsonDecode(rawResponse);

      String getVal(String path) {
         if (path.isEmpty) return '';
         final parts = path.split('.');
         dynamic current = json;
         for (var part in parts) {
           if (current is Map && current.containsKey(part)) {
             current = current[part];
           } else {
             return '';
           }
         }
         return current?.toString() ?? '';
      }

      String stdout = getVal(preset.stdoutPath);
      String stderr = getVal(preset.stderrPath);
      if (stderr.isEmpty && preset.errorPath.isNotEmpty) {
        stderr = getVal(preset.errorPath);
      }
      String time = getVal(preset.executionTimePath);
      if (time.isEmpty) time = '${stopwatch.elapsedMilliseconds}ms';
      String memory = getVal(preset.memoryPath);

      // Raw output fallback for testing connection
      if (stdout.isEmpty && stderr.isEmpty && response.statusCode == 200) {
        stdout = rawResponse;
      } else if (response.statusCode != 200) {
        stderr = 'Error ${response.statusCode}: $rawResponse';
      }

      return CompilerResult(
        stdout: stdout,
        stderr: stderr,
        executionTime: time,
        memory: memory,
      );
    } catch (_) {
      // If it's not JSON, return as stdout if success, else stderr
      if (response.statusCode == 200) {
        return CompilerResult(
          stdout: rawResponse,
          stderr: '',
          executionTime: '${stopwatch.elapsedMilliseconds}ms',
          memory: '',
        );
      } else {
        return CompilerResult(
          stdout: '',
          stderr: 'HTTP ${response.statusCode}: $rawResponse',
          executionTime: '${stopwatch.elapsedMilliseconds}ms',
          memory: '',
        );
      }
    }
  }
}
