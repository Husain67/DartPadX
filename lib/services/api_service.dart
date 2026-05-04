import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiService {
  static const String defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  // Obfuscated key
  static final String defaultOneCompilerKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));


  Future<Map<String, dynamic>> executeCode({
    required String code,
    required String stdin,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    if (useDefault || preset == null) {
      return _executeOneCompiler(code, stdin);
    } else {
      return _executeCustomAPI(code, stdin, preset);
    }
  }

  Future<Map<String, dynamic>> _executeOneCompiler(String code, String stdin) async {
    final response = await http.post(
      Uri.parse(defaultOneCompilerUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': defaultOneCompilerKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        'language': 'dart',
        'stdin': stdin,
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
      return {
        'stdout': data['stdout'] ?? '',
        'stderr': data['stderr'] ?? '',
        'error': data['exception'] ?? '',
        'executionTime': data['executionTime']?.toString() ?? '',
        'memory': '',
      };
    } else {
      throw Exception('OneCompiler API Error: \${response.statusCode} - \${response.body}');
    }
  }

  Future<Map<String, dynamic>> _executeCustomAPI(String code, String stdin, CompilerPreset preset) async {
    Map<String, String> requestHeaders = Map.from(preset.headers);
    Map<String, String> requestQueryParams = Map.from(preset.queryParams);

    // Apply Auth
    switch (preset.authType) {
      case 'API-Key Header':
        requestHeaders[preset.authKey] = preset.authValue;
        break;
      case 'Bearer Token':
        requestHeaders['Authorization'] = 'Bearer \${preset.authValue}';
        break;
      case 'Basic Auth':
        final encoded = base64Encode(utf8.encode(preset.authValue));
        requestHeaders['Authorization'] = 'Basic \$encoded';
        break;
      case 'Query Param':
        requestQueryParams[preset.authKey] = preset.authValue;
        break;
    }

    Uri uri = Uri.parse(preset.endpoint);
    if (requestQueryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...requestQueryParams,
      });
    }

    // Prepare body
    String body = preset.bodyTemplate;
    // Replace placeholders but remove quotes around JSON-encoded string to fit directly into the template
    String encodedCode = jsonEncode(code);
    encodedCode = encodedCode.substring(1, encodedCode.length - 1); // remove outer quotes
    String encodedStdin = jsonEncode(stdin);
    encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

    body = body.replaceAll('{code}', encodedCode);
    body = body.replaceAll('{stdin}', encodedStdin);
    body = body.replaceAll('{language}', 'dart');

    http.Response response;
    try {
      if (preset.method == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: body);
      } else {
        response = await http.post(uri, headers: requestHeaders, body: body);
      }
    } catch (e) {
      throw Exception('Network Error: \$e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return {
          'stdout': response.body,
          'stderr': '',
          'error': 'Failed to parse JSON response',
        };
      }

      return {
        'stdout': _extractValue(data, preset.stdoutPath)?.toString() ?? '',
        'stderr': _extractValue(data, preset.stderrPath)?.toString() ?? '',
        'error': _extractValue(data, preset.errorPath)?.toString() ?? '',
        'executionTime': _extractValue(data, preset.executionTimePath)?.toString() ?? '',
        'memory': _extractValue(data, preset.memoryPath)?.toString() ?? '',
        'raw': response.body,
      };
    } else {
      throw Exception('API Error: \${response.statusCode} - \${response.body}');
    }
  }

  dynamic _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    List<String> keys = path.split('.');
    dynamic current = data;
    for (String key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List && int.tryParse(key) != null) {
        int index = int.parse(key);
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }
}
