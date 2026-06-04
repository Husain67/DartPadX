import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ApiService {
  static Future<Map<String, dynamic>> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
  }) async {
    if (preset.endpointUrl.isEmpty) {
      return {'error': 'Endpoint URL is empty. Please check your compiler preset.'};
    }

    try {
      final uri = Uri.parse(preset.endpointUrl);

      // Prepare headers
      final headers = <String, String>{};
      for (var header in preset.headers) {
        String val = header.value;
        if (val.contains('{authValue}')) {
          val = val.replaceAll('{authValue}', preset.authValue);
        }
        headers[header.key] = val;
      }

      if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
         headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      } else if (preset.authType == 'API-Key Header' && !preset.headers.any((h) => h.value.contains('{authValue}'))) {
         // Fallback if they didn't map it dynamically
         headers['x-api-key'] = preset.authValue;
      }

      // Prepare query params
      final Map<String, String> qParams = {};
      for (var param in preset.queryParams) {
         String val = param.value;
         if (val.contains('{authValue}')) {
           val = val.replaceAll('{authValue}', preset.authValue);
         }
         qParams[param.key] = val;
      }
      if (preset.authType == 'Query Param' && !preset.queryParams.any((p) => p.value.contains('{authValue}'))) {
         qParams['api_key'] = preset.authValue;
      }

      final finalUri = uri.replace(queryParameters: qParams.isNotEmpty ? qParams : null);

      // Prepare body
      String bodyString = preset.requestBodyTemplate;

      // Need to safely inject stringified code/stdin inside JSON
      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final escapedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

      bodyString = bodyString.replaceAll('{code}', escapedCode);
      bodyString = bodyString.replaceAll('{stdin}', escapedStdin);

      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(
          finalUri,
          headers: headers,
          body: bodyString,
        );
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(
          finalUri,
          headers: headers,
          body: bodyString,
        );
      } else {
        response = await http.get(
          finalUri,
          headers: headers,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        return {
          'stdout': _getValueByPath(responseData, preset.responseStdoutPath),
          'stderr': _getValueByPath(responseData, preset.responseStderrPath),
          'error': _getValueByPath(responseData, preset.responseErrorPath),
          'executionTime': _getValueByPath(responseData, preset.responseTimePath),
          'memory': _getValueByPath(responseData, preset.responseMemoryPath),
          'raw': response.body, // Useful for testing connection
        };
      } else {
         return {
           'error': 'HTTP Error ${response.statusCode}: ${response.body}'
         };
      }
    } catch (e) {
      return {'error': 'Execution failed: $e'};
    }
  }

  static String _getValueByPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return '';

    final keys = path.split('.');
    dynamic current = json;

    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }

    return current?.toString() ?? '';
  }
}
