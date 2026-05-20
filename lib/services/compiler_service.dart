import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../models/models.dart';

class CompilerService {
  static final String _defaultOneCompilerKey = String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM='));

  Future<void> runCode(String code, String stdin, WidgetRef ref) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');

    try {
      final response = await http.post(
        url,
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': _defaultOneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        body: jsonEncode({
          "language": "dart",
          "stdin": stdin,
          "files": [
            {
              "name": "main.dart",
              "content": code
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ref.read(executionProvider.notifier).setOutput(
          stdout: data['stdout'] ?? '',
          stderr: data['stderr'] ?? data['exception'] ?? '',
          time: data['executionTime']?.toString() ?? '',
          memory: '',
        );
      } else {
        ref.read(executionProvider.notifier).setOutput(
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      ref.read(executionProvider.notifier).setOutput(
        stderr: 'Error: $e',
      );
    }
  }

  Future<void> runCustomCode(String code, String stdin, PresetModel preset, WidgetRef ref) async {
    final url = Uri.parse(preset.endpoint);

    Map<String, String> requestHeaders = Map.from(preset.headers);

    // Auth Type Handling
    if (preset.authType == 'API-Key Header') {
        // Assume key and value are set in headers, but if not we can't easily guess.
        // Usually users will set the header manually, or we can look for common keys.
        // If they provided authValue, we could add it to a generic header, but it's
        // better if they configure it in the dynamic headers table.
    } else if (preset.authType == 'Bearer Token') {
        requestHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        requestHeaders['Authorization'] = 'Basic $encoded';
    }

    Uri requestUrl = url;
    if (preset.queryParams.isNotEmpty) {
       requestUrl = url.replace(queryParameters: preset.queryParams);
    }

    if (preset.authType == 'Query Param') {
         final params = Map<String, String>.from(requestUrl.queryParameters);
         // Difficult to guess param name, relying on user to set it in query table
         requestUrl = requestUrl.replace(queryParameters: params);
    }

    String bodyStr = preset.bodyTemplate;

    // Remove enclosing quotes from code if any for JSON correctness inside templates
    String encodedCode = jsonEncode(code);
    encodedCode = encodedCode.substring(1, encodedCode.length - 1);

    String encodedStdin = jsonEncode(stdin);
    encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

    bodyStr = bodyStr.replaceAll('{code}', encodedCode);
    bodyStr = bodyStr.replaceAll('{stdin}', encodedStdin);
    bodyStr = bodyStr.replaceAll('{language}', 'dart');

    try {
      http.Response response;
      if (preset.method == 'POST') {
        response = await http.post(requestUrl, headers: requestHeaders, body: bodyStr);
      } else if (preset.method == 'PUT') {
        response = await http.put(requestUrl, headers: requestHeaders, body: bodyStr);
      } else {
        response = await http.get(requestUrl, headers: requestHeaders);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        final stdout = _extractValue(data, preset.responseStdoutPath);
        final stderr = _extractValue(data, preset.responseStderrPath);
        final error = _extractValue(data, preset.responseErrorPath);
        final time = _extractValue(data, preset.responseTimePath);
        final memory = _extractValue(data, preset.responseMemoryPath);

        ref.read(executionProvider.notifier).setOutput(
          stdout: stdout ?? '',
          stderr: stderr ?? error ?? '',
          time: time ?? '',
          memory: memory ?? '',
        );
      } else {
        ref.read(executionProvider.notifier).setOutput(
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      ref.read(executionProvider.notifier).setOutput(
        stderr: 'Error: $e',
      );
    }
  }

  String? _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
