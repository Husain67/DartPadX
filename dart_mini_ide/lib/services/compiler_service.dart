import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerOutput {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  CompilerOutput({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
  });
}

class CompilerService {
  static const String _oneCompilerKey = String.fromEnvironment('OC_API_KEY');

  Future<CompilerOutput> executeCode({
    required String code,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    if (useDefault || preset == null) {
      return _executeOneCompiler(code);
    } else {
      return _executeCustomPreset(code, preset);
    }
  }

  Future<CompilerOutput> _executeOneCompiler(String code) async {
    try {
      if (_oneCompilerKey.isEmpty) {
        return CompilerOutput(
          stdout: '',
          stderr: '',
          error: 'Missing API Key. Please run with --dart-define=OC_API_KEY=...',
          executionTime: '',
          memory: '',
        );
      }
      final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': _oneCompilerKey,
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CompilerOutput(
          stdout: data['stdout']?.toString() ?? '',
          stderr: data['stderr']?.toString() ?? '',
          error: data['exception']?.toString() ?? '',
          executionTime: data['executionTime']?.toString() ?? '',
          memory: '',
        );
      } else {
        return CompilerOutput(
          stdout: '',
          stderr: 'HTTP ${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return CompilerOutput(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  Future<CompilerOutput> _executeCustomPreset(String code, CompilerPreset preset) async {
    try {
      String rawBody = preset.bodyTemplate;

      // Basic escaping to ensure valid JSON when replacing
      String escapedCode = const JsonEncoder().convert(code);
      if (escapedCode.startsWith('"') && escapedCode.endsWith('"')) {
          escapedCode = escapedCode.substring(1, escapedCode.length - 1);
      }

      rawBody = rawBody.replaceAll('{code}', escapedCode);
      rawBody = rawBody.replaceAll('{language}', 'dart');
      rawBody = rawBody.replaceAll('{stdin}', '');

      Uri uri = Uri.parse(preset.url);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      http.Response response;
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: preset.headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: preset.headers, body: rawBody);
      } else {
        response = await http.post(uri, headers: preset.headers, body: rawBody);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String extractPath(dynamic source, String path) {
           if (path.isEmpty || source == null) return '';
           final parts = path.split('.');
           dynamic current = source;
           for (var p in parts) {
             if (current is Map && current.containsKey(p)) {
               current = current[p];
             } else {
               return '';
             }
           }
           return current?.toString() ?? '';
        }

        return CompilerOutput(
          stdout: extractPath(data, preset.stdoutPath),
          stderr: extractPath(data, preset.stderrPath),
          error: extractPath(data, preset.errorPath),
          executionTime: extractPath(data, preset.executionTimePath),
          memory: extractPath(data, preset.memoryPath),
        );
      } else {
        return CompilerOutput(
          stdout: '',
          stderr: 'HTTP Error ${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return CompilerOutput(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }
}
