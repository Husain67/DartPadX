import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ExecutionService {
  static Future<Map<String, String>> execute({
    required String code,
    required String stdin,
    required bool useDefaultOneCompiler,
    CompilerPreset? customPreset,
  }) async {
    if (useDefaultOneCompiler) {
      return await _executeDefaultOneCompiler(code: code, stdin: stdin);
    } else {
      if (customPreset == null) {
        return {
          'stdout': '',
          'stderr': 'No custom preset selected',
          'executionTime': '',
          'memory': '',
        };
      }
      return await _executeCustom(code: code, stdin: stdin, preset: customPreset);
    }
  }

  static Future<Map<String, String>> _executeDefaultOneCompiler({
    required String code,
    required String stdin,
  }) async {
    try {
      final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
      final headers = {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
      };
      final body = jsonEncode({
        'language': 'dart',
        'stdin': stdin,
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'stdout': data['stdout']?.toString() ?? '',
          'stderr': data['stderr']?.toString() ?? data['exception']?.toString() ?? '',
          'executionTime': data['executionTime']?.toString() ?? '',
          'memory': '',
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'HTTP ${response.statusCode}: ${response.body}',
          'executionTime': '',
          'memory': '',
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Error: $e',
        'executionTime': '',
        'memory': '',
      };
    }
  }

  static Future<Map<String, String>> _executeCustom({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    try {
      String processedUrl = preset.endpointUrl;
      final uriBuilder = Uri.parse(processedUrl).replace();
      Map<String, String> queryParams = Map.from(uriBuilder.queryParameters);

      preset.queryParams.forEach((key, value) {
        queryParams[key] = value;
      });

      String processedBody = preset.bodyTemplate
          .replaceAll('{stdin}', _escapeJsonString(stdin))
          .replaceAll('{language}', 'dart');

      if (processedBody.contains('"{code}"')) {
        processedBody = processedBody.replaceAll('"{code}"', jsonEncode(code));
      } else {
         processedBody = processedBody.replaceAll('{code}', _escapeJsonString(code));
      }

      Map<String, String> finalHeaders = Map.from(preset.headers);

      if (preset.authType == 'API-Key Header') {
        finalHeaders.forEach((key, value) {
          if (value == '{authValue}') {
            finalHeaders[key] = preset.authValue;
          }
        });
      } else if (preset.authType == 'Bearer Token') {
        finalHeaders['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        final _ = encoded;
        finalHeaders['Authorization'] = 'Basic $encoded';
      } else if (preset.authType == 'Query Param') {
        queryParams['auth'] = preset.authValue; // Simplistic approach, some APIs use different keys
      }

      final url = Uri.parse(processedUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(url, headers: finalHeaders, body: processedBody);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(url, headers: finalHeaders, body: processedBody);
      } else {
        response = await http.get(url, headers: finalHeaders);
      }

      final data = jsonDecode(response.body);

      return {
        'stdout': _extractPath(data, preset.stdoutPath) ?? '',
        'stderr': _extractPath(data, preset.stderrPath) ?? _extractPath(data, preset.errorPath) ?? (response.statusCode != 200 ? 'HTTP ${response.statusCode}: ${response.body}' : ''),
        'executionTime': _extractPath(data, preset.executionTimePath) ?? '',
        'memory': _extractPath(data, preset.memoryPath) ?? '',
        'rawResponse': response.body,
      };

    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Error: $e',
        'executionTime': '',
        'memory': '',
      };
    }
  }

  static String _escapeJsonString(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t');
  }

  static String? _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
