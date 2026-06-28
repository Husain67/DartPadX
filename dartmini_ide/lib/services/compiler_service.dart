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

class CompilerService {
  static const String _oneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  // User explicitly asked for this hardcoded API key for out-of-the-box working default preset
  static const String _oneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static Future<ExecutionResult> runCode({
    required String code,
    required bool useOneCompiler,
    CompilerPreset? preset,
  }) async {
    final startTime = DateTime.now();
    try {
      if (useOneCompiler) {
        return await _runOneCompiler(code, startTime);
      } else {
        if (preset == null) {
          throw Exception("No compiler preset selected.");
        }
        return await _runCustomCompiler(code, preset, startTime);
      }
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds.toString() + 'ms';
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: elapsed,
        memory: 'N/A',
      );
    }
  }

  static Future<ExecutionResult> _runOneCompiler(String code, DateTime startTime) async {
    final response = await http.post(
      Uri.parse(_oneCompilerUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': _oneCompilerKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      body: jsonEncode({
        'language': 'dart',
        'stdin': 'DartMiniUser', // Mock stdin for the example
        'files': [
          {
            'name': 'main.dart',
            'content': code,
          }
        ],
      }),
    );

    final elapsed = DateTime.now().difference(startTime).inMilliseconds.toString() + 'ms';

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ExecutionResult(
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? '',
        error: data['exception'] ?? '',
        executionTime: (data['executionTime'] ?? elapsed).toString(),
        memory: 'N/A', // OneCompiler doesn't reliably return memory in this endpoint structure usually, but mapping just in case
      );
    } else {
      throw Exception('OneCompiler API Error: \${response.statusCode} - \${response.body}');
    }
  }

  static Future<ExecutionResult> _runCustomCompiler(String code, CompilerPreset preset, DateTime startTime) async {
    // Basic substitution
    String body = preset.requestBodyTemplate
        .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{language}', 'dart')
        .replaceAll('{stdin}', 'DartMiniUser');

    // Make sure valid JSON if possible, basic fix for encoding quotes issues if used inside JSON template
    // This is simple replacement, real implementation might need more robust JSON parsing but this meets reqs.

    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    http.Response response;

    // Auth headers
    Map<String, String> requestHeaders = Map.from(preset.headers);
    if (!requestHeaders.containsKey('Content-Type')) {
        requestHeaders['Content-Type'] = 'application/json';
    }

    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: requestHeaders, body: body);
    } else {
      response = await http.get(uri, headers: requestHeaders);
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds.toString() + 'ms';

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      String extractPath(Map<String, dynamic> source, String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = source;
        for (final part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current.toString();
      }

      return ExecutionResult(
        stdout: extractPath(data, preset.stdoutPath),
        stderr: extractPath(data, preset.stderrPath),
        error: extractPath(data, preset.errorPath),
        executionTime: extractPath(data, preset.executionTimePath).isNotEmpty ? extractPath(data, preset.executionTimePath) : elapsed,
        memory: extractPath(data, preset.memoryPath),
      );
    } else {
      throw Exception('Custom API Error: \${response.statusCode} - \${response.body}');
    }
  }
}
