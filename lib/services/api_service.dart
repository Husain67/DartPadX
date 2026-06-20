import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiService {
  Future<Map<String, String>> executeCode(String code, CompilerPreset preset) async {
    if (preset.id == 'blank' || preset.endpointUrl.isEmpty) {
      return {'stdout': '', 'stderr': 'Preset not configured or endpoint is empty.'};
    }

    try {
      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams);
      final headers = Map<String, String>.from(preset.headers);

      String requestBody = preset.requestBodyTemplate
          .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
          .replaceAll('{stdin}', '')
          .replaceAll('{language}', 'dart');

      http.Response response;

      switch (preset.httpMethod.toUpperCase()) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: requestBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: requestBody);
          break;
        case 'GET':
        default:
          response = await http.get(uri, headers: headers);
          break;
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      return {
        'stdout': _extractPath(jsonResponse, preset.stdoutPath),
        'stderr': _extractPath(jsonResponse, preset.stderrPath).isEmpty
            ? _extractPath(jsonResponse, preset.errorPath)
            : _extractPath(jsonResponse, preset.stderrPath),
        'executionTime': _extractPath(jsonResponse, preset.executionTimePath),
        'memory': _extractPath(jsonResponse, preset.memoryPath),
      };
    } catch (e) {
      return {'stderr': 'Execution error: $e'};
    }
  }

  String _extractPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return '';

    final keys = path.split('.');
    dynamic current = json;

    for (final key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }

    return current?.toString() ?? '';
  }
}
