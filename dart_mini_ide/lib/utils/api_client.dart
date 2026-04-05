import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiClient {
  static Future<Map<String, dynamic>> executeCode({
    required CompilerPreset preset,
    required String code,
    String stdin = '',
  }) async {
    try {
      final uriStr = preset.url.trim();
      if (uriStr.isEmpty) {
        return {'error': 'API URL is empty. Please check the preset configuration.'};
      }

      Uri uri = Uri.parse(uriStr);
      if (preset.queryParams.isNotEmpty) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams.addAll(preset.queryParams);
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $encoded';
      } else if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        // Assume the key is already in headers if properly set up, but let's be safe if they use standard ones
        // In Constants we put it in headers. If they used "API-Key Header", we might want to ensure 'x-api-key' or similar is set if they didn't map it.
      }

      String bodyStr = preset.bodyTemplate;

      // Replace {code} properly. If JSON, encode it.
      if (headers['content-type']?.contains('json') == true) {
        String jsonCode = jsonEncode(code);
        // Remove surrounding quotes if they put {code} without quotes, or if they put "{code}" handle accordingly.
        // Let's assume they put "{code}" in the template and we replace "{code}" with the JSON encoded code.
        // Wait, standard templates like JDoodle use "{code}". But jsonEncode(code) returns something with quotes.
        // For OneCompiler template: "content": {code} -> jsonEncode(code) will be "some code string"
        bodyStr = bodyStr.replaceAll('{code}', jsonCode);
        bodyStr = bodyStr.replaceAll('{stdin}', stdin.replaceAll('"', '\\"').replaceAll('\n', '\\n'));
      } else if (headers['content-type']?.contains('x-www-form-urlencoded') == true) {
        bodyStr = bodyStr.replaceAll('{code}', Uri.encodeComponent(code));
        bodyStr = bodyStr.replaceAll('{stdin}', Uri.encodeComponent(stdin));
      } else {
        bodyStr = bodyStr.replaceAll('{code}', code);
        bodyStr = bodyStr.replaceAll('{stdin}', stdin);
      }

      http.Response response;
      final method = preset.method.toUpperCase();

      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      final isJson = response.headers['content-type']?.contains('json') == true;
      dynamic responseBody = response.body;

      if (isJson) {
        try {
          responseBody = jsonDecode(response.body);
        } catch (_) {}
      }

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
        'rawBody': response.body,
        'preset': preset,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static String extractFromPath(dynamic jsonMap, String path) {
    if (path.isEmpty || jsonMap == null) return '';
    if (jsonMap is! Map) return '';

    List<String> keys = path.split('.');
    dynamic current = jsonMap;

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