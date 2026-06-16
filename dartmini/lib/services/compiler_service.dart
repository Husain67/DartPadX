import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class CompilerService {
  static const String defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String defaultOneCompilerKey = String.fromEnvironment(
    'ONECOMPILER_API_KEY',
    defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
  );

  static Future<Map<String, dynamic>> executeCode({
    required String code,
    required String stdin,
    required bool useDefault,
    CompilerPreset? preset,
  }) async {
    if (useDefault || preset == null) {
      return _executeDefaultOneCompiler(code, stdin);
    } else {
      return _executeCustomPreset(code, stdin, preset);
    }
  }

  static Future<Map<String, dynamic>> _executeDefaultOneCompiler(String code, String stdin) async {
    try {
      final response = await http.post(
        Uri.parse(defaultOneCompilerUrl),
        headers: {
          'x-rapidapi-key': defaultOneCompilerKey,
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': stdin,
          'files': [
            {
              'name': 'main.dart',
              'content': code,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'stdout': data['stdout'] ?? '',
          'stderr': data['stderr'] ?? data['exception'] ?? '',
          'executionTime': data['executionTime']?.toString() ?? '',
          'memory': '',
          'raw': data,
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'Error: \${response.statusCode} - \${response.body}',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Exception: \$e',
        'raw': null,
      };
    }
  }

  static Future<Map<String, dynamic>> _executeCustomPreset(String code, String stdin, CompilerPreset preset) async {
    try {
      if (preset.endpointUrl.isEmpty) {
        return {'stdout': '', 'stderr': 'Error: Endpoint URL is empty.'};
      }

      String bodyStr = preset.requestBodyTemplate
          .replaceAll('{code}', _escapeJsonString(code))
          .replaceAll('{stdin}', _escapeJsonString(stdin))
          .replaceAll('{language}', 'dart');

      Map<String, String> headers = Map.from(preset.headers);

      // Handle simple auth appending if necessary based on authType
      if (preset.authType == 'Bearer Token') {
         // Assuming user puts token in headers manually or we replace a placeholder
      }

      http.Response response;
      Uri uri = Uri.parse(preset.endpointUrl);

      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        // Default to POST
        // If content type is urlencoded, body might need to be form fields instead of raw string
        if (headers['Content-Type'] == 'application/x-www-form-urlencoded') {
            // Simplified parsing for urlencoded if template is like code={code}&language=dart
            response = await http.post(uri, headers: headers, body: bodyStr);
        } else {
            response = await http.post(uri, headers: headers, body: bodyStr);
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (e) {
          data = response.body; // Fallback if not JSON
        }

        return {
          'stdout': _extractValue(data, preset.stdoutPath),
          'stderr': _extractValue(data, preset.stderrPath) + (_extractValue(data, preset.errorPath)),
          'executionTime': _extractValue(data, preset.executionTimePath),
          'memory': _extractValue(data, preset.memoryPath),
          'raw': data,
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'HTTP Error: \${response.statusCode}\n\${response.body}',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Exception: \$e',
        'raw': null,
      };
    }
  }

  static String _escapeJsonString(String str) {
    return str.replaceAll('\\', '\\\\')
              .replaceAll('"', '\\"')
              .replaceAll('\n', '\\n')
              .replaceAll('\r', '\\r')
              .replaceAll('\t', '\\t');
  }

  static String _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
    if (data is! Map) return data.toString();

    List<String> keys = path.split('.');
    dynamic current = data;

    for (String key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}
