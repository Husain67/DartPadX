import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiService {
  static const String _defaultUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _defaultApiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  static Future<Map<String, dynamic>> runOneCompiler(String code, String stdin) async {
    final response = await http.post(
      Uri.parse(_defaultUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': _defaultApiKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [
          {"name": "index.dart", "content": code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'stdout': data['stdout'] ?? '',
        'stderr': data['stderr'] ?? data['exception'] ?? '',
        'time': data['executionTime']?.toString() ?? '',
        'memory': '',
      };
    } else {
      throw Exception('Failed to execute code: \${response.statusCode}\n\${response.body}');
    }
  }

  static Future<Map<String, dynamic>> runCustomPreset(CompilerPreset preset, String code, String stdin) async {
    if (preset.endpointUrl.isEmpty) {
      throw Exception('Endpoint URL is missing for this preset.');
    }

    Map<String, String> headers = Map.from(preset.headers);

    String bodyStr = preset.bodyTemplate;

    String encodedCode = jsonEncode(code);
    encodedCode = encodedCode.substring(1, encodedCode.length - 1);

    String encodedStdin = jsonEncode(stdin);
    encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

    bodyStr = bodyStr.replaceAll('{code}', encodedCode);
    bodyStr = bodyStr.replaceAll('{stdin}', encodedStdin);
    bodyStr = bodyStr.replaceAll('{language}', 'dart');

    Uri uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    http.Response response;
    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: headers, body: bodyStr);
    } else if (preset.httpMethod.toUpperCase() == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (preset.httpMethod.toUpperCase() == 'PUT') {
      response = await http.put(uri, headers: headers, body: bodyStr);
    } else {
      throw Exception('Unsupported HTTP Method: \${preset.httpMethod}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic data = jsonDecode(response.body);

      String extractPath(dynamic json, String path) {
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

      return {
        'stdout': extractPath(data, preset.stdoutPath),
        'stderr': extractPath(data, preset.stderrPath).isEmpty ? extractPath(data, preset.errorPath) : extractPath(data, preset.stderrPath),
        'time': extractPath(data, preset.timePath),
        'memory': extractPath(data, preset.memoryPath),
      };
    } else {
      throw Exception('API Request Failed: \${response.statusCode}\n\${response.body}');
    }
  }
}
