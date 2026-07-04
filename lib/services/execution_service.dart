import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionService {
  static Future<Map<String, String>> runCode({
    required CompilerPreset preset,
    required String code,
    required String stdin,
  }) async {
    try {
      // Prepare body
      String bodyStr = preset.requestBodyTemplate;
      // We must escape quotes and newlines in code to inject into JSON,
      // however a better way is to decode the template, replace placeholders in values, and encode.
      // But template might have placeholders directly in string values.

      // Let's replace placeholders cleanly
      String safeCode = jsonEncode(code);
      safeCode = safeCode.substring(1, safeCode.length - 1); // remove quotes

      String safeStdin = jsonEncode(stdin);
      safeStdin = safeStdin.substring(1, safeStdin.length - 1);

      bodyStr = bodyStr.replaceAll('{code}', safeCode)
                       .replaceAll('{stdin}', safeStdin)
                       .replaceAll('{language}', 'dart');

      // Prepare headers
      Map<String, String> headers = Map.from(preset.headers);
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        if (preset.authValue.contains(':')) {
          var parts = preset.authValue.split(':');
          headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
        } else {
          headers['Authorization'] = preset.authValue;
        }
      }
      if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      // Prepare URL and Query Params
      Uri url = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        url = url.replace(queryParameters: preset.queryParams);
      }

      http.Response response;

      if (preset.httpMethod == 'POST') {
        response = await http.post(url, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(url, headers: headers, body: bodyStr);
      } else {
        throw Exception('Unsupported HTTP Method: ${preset.httpMethod}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String out = _getValueByPath(data, preset.responseStdoutPath) ?? '';
        String err = _getValueByPath(data, preset.responseStderrPath) ?? '';
        String exc = _getValueByPath(data, preset.responseErrorPath) ?? '';
        String time = _getValueByPath(data, preset.responseTimePath) ?? '';
        String mem = _getValueByPath(data, preset.responseMemoryPath) ?? '';

        if (exc.isNotEmpty) {
          err = err.isNotEmpty ? '$err\n$exc' : exc;
        }

        return {
          'stdout': out,
          'stderr': err,
          'time': time,
          'memory': mem,
        };
      } else {
        return {
          'stdout': '',
          'stderr': 'HTTP Error ${response.statusCode}: ${response.body}',
          'time': '',
          'memory': '',
        };
      }
    } catch (e) {
      return {
        'stdout': '',
        'stderr': 'Request failed: $e',
        'time': '',
        'memory': '',
      };
    }
  }

  static String? _getValueByPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
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
