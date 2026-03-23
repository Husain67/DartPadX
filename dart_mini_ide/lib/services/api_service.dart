import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';

class ApiService {
  final Ref ref;

  // Hardcoded default fallback for OneCompiler API key if not in preset
  static const String _defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  ApiService(this.ref);

  Future<Map<String, dynamic>> execute(String code) async {
    final compilerState = ref.read(compilerProvider);

    if (compilerState.useDefaultOneCompiler) {
      return await _executeOneCompiler(code);
    } else {
      final preset = compilerState.activePreset;
      if (preset == null) {
        throw Exception("No active custom compiler preset selected.");
      }
      return await executeCustomPreset(code, preset);
    }
  }

  Future<Map<String, dynamic>> _executeOneCompiler(String code) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final key = String.fromEnvironment('ONECOMPILER_KEY', defaultValue: _defaultOneCompilerKey);

    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': key,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };

    final body = jsonEncode({
      "language": "dart",
      "stdin": "",
      "files": [
        {
          "name": "main.dart",
          "content": code
        }
      ]
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'stdout': data['stdout'] ?? '',
          'stderr': data['stderr'] ?? data['exception'] ?? '',
          'executionTime': data['executionTime']?.toString() ?? '',
          'memory': '',
        };
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Execution failed: $e');
    }
  }

  Future<Map<String, dynamic>> executeCustomPreset(String code, var preset) async {
    final uri = Uri.parse(preset.endpointUrl);

    // Add query params
    var finalUri = uri;
    if (preset.queryParams.isNotEmpty) {
       finalUri = uri.replace(queryParameters: preset.queryParams);
    }

    final headers = Map<String, String>.from(preset.headers);
    headers['Content-Type'] = 'application/json';

    // Handle Auth
    if (preset.authType == 'API-Key Header') {
       headers['Authorization'] = preset.authValue; // usually custom header, but simple fallback
    } else if (preset.authType == 'Bearer Token') {
       headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
       final auth = base64Encode(utf8.encode(preset.authValue));
       headers['Authorization'] = 'Basic $auth';
    }

    // Prepare body
    String bodyStr = preset.bodyTemplate;
    // Simple placeholder replacement. Note: json encoding code to escape quotes.
    String encodedCode = jsonEncode(code);
    // Remove leading/trailing quotes from jsonEncode to just get the escaped string if injecting directly into JSON
    encodedCode = encodedCode.substring(1, encodedCode.length - 1);

    bodyStr = bodyStr.replaceAll('{code}', encodedCode);
    bodyStr = bodyStr.replaceAll('{language}', 'dart');
    bodyStr = bodyStr.replaceAll('{stdin}', '');

    try {
      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(finalUri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(finalUri, headers: headers);
      }

      final data = jsonDecode(response.body);

      // Deep resolve
      dynamic resolvePath(Map<String, dynamic> map, String path) {
        if (path.isEmpty) return null;
        List<String> keys = path.split('.');
        dynamic current = map;
        for (String key in keys) {
          if (current is Map && current.containsKey(key)) {
            current = current[key];
          } else {
            return null;
          }
        }
        return current;
      }

      return {
        'stdout': resolvePath(data, preset.stdoutPath)?.toString() ?? '',
        'stderr': resolvePath(data, preset.stderrPath)?.toString() ?? resolvePath(data, preset.errorPath)?.toString() ?? '',
        'executionTime': resolvePath(data, preset.executionTimePath)?.toString() ?? '',
        'memory': resolvePath(data, preset.memoryPath)?.toString() ?? '',
      };
    } catch (e) {
      throw Exception('Custom API Error: $e');
    }
  }
}
