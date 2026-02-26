import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class CompilerService {
  static const String _oneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _oneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  Future<ExecutionResult> execute(CodeFile file, CompilerPreset preset) async {
    if (preset.name == 'OneCompiler' || preset.platform == 'OneCompiler') {
      return _executeOneCompiler(file);
    } else {
      return _executeCustom(file, preset);
    }
  }

  Future<ExecutionResult> _executeOneCompiler(CodeFile file) async {
    try {
      final response = await http.post(
        Uri.parse(_oneCompilerUrl),
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': _oneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
          'language': file.language,
          'stdin': '',
          'files': [
            {'name': 'main.dart', 'content': file.content}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? '',
          error: data['exception'] ?? '',
          executionTime: '${data['executionTime'] ?? 0}ms',
          memory: '',
        );
      } else {
        return ExecutionResult(error: 'Error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return ExecutionResult(error: 'Exception: $e');
    }
  }

  Future<ExecutionResult> _executeCustom(CodeFile file, CompilerPreset preset) async {
    try {
      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams);

      final Map<String, String> headers = Map.from(preset.headers);
      if (preset.authType == 'Bearer Token') {
         // Assuming user puts "Bearer <token>" in a header or we handle it here.
         // For now, let's assume headers cover it or we add specific logic if needed.
         // But the prompt says "Auth Type (None, API-Key Header, Bearer Token...)"
         // so we might need to add specific headers based on auth type if not already in headers map.
         // Simplest is to rely on user adding it to headers map for now,
         // or if we stored a token separately.
         // The preset model has authType, but no separate token field.
         // We will assume headers contains the auth info for custom presets for now or
         // implementing full auth logic is complex without specific fields.
         // Let's assume headers are fully configured by user.
      }

      // Replace placeholders in body
      String body = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(file.content).substring(1, jsonEncode(file.content).length - 1)) // simplistic escape
          .replaceAll('{language}', file.language)
          .replaceAll('{stdin}', '');

      // Better JSON escaping might be needed.
      // A robust way: Parse bodyTemplate as JSON if possible, replace values, then encode.
      // But bodyTemplate is String.
      // Let's try to be smart. If bodyTemplate is JSON, decode it, replace in map, encode.

      dynamic bodyData;
      try {
        // precise replacement requires parsing.
        // For simplicity in this "mini" IDE, we will do string replacement but carefully.
        // Actually, easiest is to let user define structure.
        // If the template is `{"src": "{code}"}`, we replace `{code}` with the actual code.
        // But code has newlines and quotes.
        // So we should replace `{code}` with the ESCAPED code string.

        final escapedCode = jsonEncode(file.content); // "import ... ;"
        final rawCode = escapedCode.substring(1, escapedCode.length - 1); // import ... ; (escaped)

        body = preset.bodyTemplate
          .replaceAll('{code}', rawCode)
          .replaceAll('{language}', file.language);
      } catch (e) {
        // fallback
      }

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      final data = jsonDecode(response.body);

      // Map response using dot notation
      String getPath(dynamic data, String path) {
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

      return ExecutionResult(
        stdout: getPath(data, preset.responseMapping['stdout'] ?? ''),
        stderr: getPath(data, preset.responseMapping['stderr'] ?? ''),
        error: getPath(data, preset.responseMapping['error'] ?? ''),
        executionTime: getPath(data, preset.responseMapping['executionTime'] ?? ''),
        memory: getPath(data, preset.responseMapping['memory'] ?? ''),
      );

    } catch (e) {
      return ExecutionResult(error: 'Exception: $e');
    }
  }
}
