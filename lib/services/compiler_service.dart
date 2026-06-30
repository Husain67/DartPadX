import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/preset_model.dart';
import '../providers/preset_provider.dart';

class CompilerService {
  static const String _oneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';
  static const String _oneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';

  static Future<Map<String, dynamic>> executeCode(String code, PresetState presetState) async {
    if (presetState.useOneCompiler) {
      return _executeOneCompiler(code);
    } else {
      final activePreset = presetState.presets.firstWhere(
        (p) => p.id == presetState.activePresetId,
        orElse: () => throw Exception('Active preset not found'),
      );
      return _executeCustomPreset(code, activePreset);
    }
  }

  static Future<Map<String, dynamic>> _executeOneCompiler(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_oneCompilerUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': _oneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
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
        final data = jsonDecode(response.body);
        return {
          'stdout': data['stdout'] ?? '',
          'stderr': data['stderr'] ?? data['exception'] ?? '',
          'executionTime': '${data['executionTime'] ?? 0} ms',
          'memory': '',
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'Error: ${response.statusCode}\n${response.body}',
          'executionTime': '',
          'memory': '',
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Network Error: $e',
        'executionTime': '',
        'memory': '',
      };
    }
  }

  static Future<Map<String, dynamic>> _executeCustomPreset(String code, PresetModel preset) async {
    try {
      Uri uri = Uri.parse(preset.url);

      // Add Query Params
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      // Add Headers
      Map<String, String> requestHeaders = {'Content-Type': 'application/json'};
      requestHeaders.addAll(preset.headers);

      // Auth
      if (preset.authType == 'Bearer Token') {
        final token = preset.headers['Authorization'] ?? '';
        if (!token.startsWith('Bearer ')) {
          requestHeaders['Authorization'] = 'Bearer $token';
        }
      } else if (preset.authType == 'API-Key Header') {
        // Handled by headers if defined correctly
      }

      // Body Template Replacement
      String requestBody = preset.bodyTemplate.replaceAll('{code}', _escapeJsonString(code));
      requestBody = requestBody.replaceAll('{language}', 'dart');
      requestBody = requestBody.replaceAll('{stdin}', '');

      http.Response response;
      if (preset.method == 'POST') {
        response = await http.post(uri, headers: requestHeaders, body: requestBody);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: requestBody);
      } else {
        response = await http.get(uri, headers: requestHeaders); // Ignore body for GET
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        String resolvePath(String path) {
          if (path.isEmpty) return '';
          dynamic current = data;
          final parts = path.split('.');
          for (final part in parts) {
            if (current is Map && current.containsKey(part)) {
              current = current[part];
            } else {
              return '';
            }
          }
          return current?.toString() ?? '';
        }

        final stdout = resolvePath(preset.responseMappings['stdout'] ?? '');
        String stderr = resolvePath(preset.responseMappings['stderr'] ?? '');
        if (stderr.isEmpty) {
           stderr = resolvePath(preset.responseMappings['error'] ?? '');
        }
        final executionTime = resolvePath(preset.responseMappings['executionTime'] ?? '');
        final memory = resolvePath(preset.responseMappings['memory'] ?? '');

        return {
          'stdout': stdout,
          'stderr': stderr,
          'executionTime': executionTime,
          'memory': memory,
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'Error: ${response.statusCode}\n${response.body}',
          'executionTime': '',
          'memory': '',
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Execution Error: $e',
        'executionTime': '',
        'memory': '',
      };
    }
  }

  static String _escapeJsonString(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }
}
