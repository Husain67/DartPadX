import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiService {
  static const String _defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String _rapidApiKey = String.fromEnvironment('RAPID_API_KEY');

  static Future<Map<String, dynamic>> executeCode({
    required String code,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    try {
      if (useDefault) {
        return await _executeDefaultOneCompiler(code);
      } else {
        if (preset == null) throw Exception('No custom preset selected');
        return await _executeCustomPreset(code, preset);
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': e.toString(),
        'time': '',
        'memory': '',
      };
    }
  }

  static Future<Map<String, dynamic>> _executeDefaultOneCompiler(String code) async {
    final uri = Uri.parse(_defaultOneCompilerUrl);
    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': _rapidApiKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };
    final body = jsonEncode({
      'language': 'dart',
      'stdin': '',
      'files': [
        {'name': 'main.dart', 'content': code}
      ]
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'stdout': data['stdout'] ?? '',
        'stderr': data['stderr'] ?? data['exception'] ?? '',
        'time': '${data["executionTime"]?.toString() ?? ""}ms',
        'memory': '',
      };
    } else {
      throw Exception('Failed to execute code: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> _executeCustomPreset(String code, CompilerPreset preset) async {
    var url = preset.url;
    if (preset.queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: {...uri.queryParameters, ...preset.queryParams}).toString();
    }

    final headers = <String, String>{...preset.headers};

    switch (preset.authType) {
      case 'API-Key Header':
        if (preset.authValue.isNotEmpty) {
          // Assuming authValue might be key:value or just value if key is defined in headers.
          // Simplification: if it contains ':', split it.
          if (preset.authValue.contains(':')) {
            final parts = preset.authValue.split(':');
            headers[parts[0].trim()] = parts[1].trim();
          } else {
            headers['Authorization'] = preset.authValue;
          }
        }
        break;
      case 'Bearer Token':
        headers['Authorization'] = 'Bearer ${preset.authValue}';
        break;
      case 'Basic Auth':
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
        break;
    }

    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{language}', 'dart')
        .replaceAll('{stdin}', '');

    http.Response response;
    final uri = Uri.parse(url);

    if (preset.method.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: headers, body: bodyStr);
    } else if (preset.method.toUpperCase() == 'PUT') {
      response = await http.put(uri, headers: headers, body: bodyStr);
    } else {
      response = await http.get(uri, headers: headers);
    }

    final data = jsonDecode(response.body);

    return {
      'stdout': _extractPath(data, preset.stdoutPath),
      'stderr': _extractPath(data, preset.stderrPath) + _extractPath(data, preset.errorPath),
      'time': _extractPath(data, preset.timePath),
      'memory': _extractPath(data, preset.memoryPath),
    };
  }

  static dynamic _extractPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}
