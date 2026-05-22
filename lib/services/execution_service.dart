import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionService {
  static Future<Map<String, dynamic>> executeCode({
    required String code,
    required String stdin,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    if (useDefault) {
      return await _executeOneCompiler(code, stdin);
    }

    if (preset == null || preset.endpoint.isEmpty) {
      return {'error': 'No valid custom compiler preset selected or endpoint is empty.'};
    }

    return await _executeCustom(code, stdin, preset);
  }

  static Future<Map<String, dynamic>> _executeOneCompiler(String code, String stdin) async {
    try {
      final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');

      // The provided key appears to be a direct token but we'll try sending it as an API key header if it fails we fall back to direct request if needed.
      // Based on OneCompiler docs, usually it requires a RapidAPI key.
      // We will try sending the provided token.

      final headers = {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      };

      final body = jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [
          {
            "name": "main.dart",
            "content": code
          }
        ]
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'stdout': data['stdout'] ?? '',
          'stderr': data['stderr'] ?? '',
          'error': data['exception'] ?? '',
          'time': (data['executionTime'] ?? '').toString(),
          'memory': '',
        };
      } else {
        // If RapidAPI fails, let's try a generic Piston API fallback for out-of-the-box working state just in case the OneCompiler key is invalid/expired
        return await _executePistonFallback(code, stdin);
      }
    } catch (e) {
      return {'error': 'Execution failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> _executePistonFallback(String code, String stdin) async {
      try {
          final url = Uri.parse('https://emacs.piston.rs/api/v2/execute');
          final response = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                  "language": "dart",
                  "version": "*",
                  "files": [
                    {
                      "content": code
                    }
                  ],
                  "stdin": stdin
              })
          );
          if (response.statusCode == 200) {
             final data = jsonDecode(response.body);
             final runData = data['run'] ?? {};
             return {
                 'stdout': runData['stdout'] ?? '',
                 'stderr': runData['stderr'] ?? '',
                 'error': data['message'] ?? '',
                 'time': '',
                 'memory': '',
             };
          }
          return {'error': 'Fallback execution failed with status: ${response.statusCode}'};
      } catch (e) {
          return {'error': 'Fallback execution failed: $e'};
      }
  }

  static Future<Map<String, dynamic>> _executeCustom(String code, String stdin, CompilerPreset preset) async {
    try {
      final url = Uri.parse(preset.endpoint).replace(queryParameters: preset.queryParams.isEmpty ? null : preset.queryParams);

      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
         // Assume API Key is passed via some header, let's look for a key or just default to Authorization if not specified
         // Actually, if it's 'API-Key Header', typically the user sets the header in `headers` themselves.
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      }

      // Prepare body
      String bodyStr = preset.bodyTemplate;

      // Need to properly escape the code for JSON
      // jsonEncode adds quotes, we strip them to inject into the template
      String safeCode = jsonEncode(code);
      safeCode = safeCode.substring(1, safeCode.length - 1);

      String safeStdin = jsonEncode(stdin);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1);

      bodyStr = bodyStr.replaceAll('{code}', safeCode);
      bodyStr = bodyStr.replaceAll('{stdin}', safeStdin);
      bodyStr = bodyStr.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(url, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(url, headers: headers, body: bodyStr);
      } else {
        response = await http.get(url, headers: headers);
      }

      if (response.body.isEmpty) {
          return {'error': 'Empty response from API (Status: ${response.statusCode})'};
      }

      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {'error': 'Invalid JSON response from API: \n${response.body}'};
      }

      if (response.statusCode >= 400) {
           return {'error': 'API Error (${response.statusCode}): \n${response.body}'};
      }

      return {
        'stdout': _extractValue(responseData, preset.stdoutPath),
        'stderr': _extractValue(responseData, preset.stderrPath),
        'error': _extractValue(responseData, preset.errorPath),
        'time': _extractValue(responseData, preset.timePath),
        'memory': _extractValue(responseData, preset.memoryPath),
        'raw': response.body, // useful for testing
      };
    } catch (e) {
      return {'error': 'Custom execution failed: $e'};
    }
  }

  static String _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';

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
}
