import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'constants.dart';

class ApiService {
  static Future<Map<String, String>> executeOneCompiler(String code) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': AppConstants.defaultOneCompilerKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      },
      body: jsonEncode({
        'language': 'dart',
        'stdin': '',
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'stdout': json['stdout']?.toString() ?? '',
        'stderr': json['stderr']?.toString() ?? json['exception']?.toString() ?? '',
        'time': json['executionTime']?.toString() ?? '',
        'memory': '',
      };
    } else {
      throw Exception('Failed to execute code: ${response.body}');
    }
  }

  static Future<Map<String, String>> executeCustom(String code, CompilerPreset preset) async {
    final uri = Uri.parse(preset.endpoint).replace(queryParameters: preset.queryParams.isEmpty ? null : preset.queryParams);

    String bodyStr = preset.bodyTemplate;
    // Replace {code} safely by encoding as JSON string and stripping quotes
    String safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    bodyStr = bodyStr.replaceAll('{code}', '"$safeCode"');
    bodyStr = bodyStr.replaceAll('{language}', '"dart"');

    http.Response response;
    final headers = Map<String, String>.from(preset.headers);

    try {
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        return {
          'stdout': _extractPath(jsonResponse, preset.responseStdoutPath) ?? '',
          'stderr': _extractPath(jsonResponse, preset.responseStderrPath) ?? '',
          'time': _extractPath(jsonResponse, preset.responseTimePath) ?? '',
          'memory': _extractPath(jsonResponse, preset.responseMemoryPath) ?? '',
          'raw': response.body, // Useful for Test Connection
        };
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Execution failed: $e');
    }
  }

  static String? _extractPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
