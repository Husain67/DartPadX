import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
  });
}

class ExecutionService {
  static const String defaultOneCompilerUrl = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
  static const String defaultOneCompilerKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

  Future<ExecutionResult> executeDefault(String code, {String stdin = ''}) async {
    try {
      final response = await http.post(
        Uri.parse(defaultOneCompilerUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': defaultOneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': stdin,
          'files': [
            {'name': 'main.dart', 'content': code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExecutionResult(
          stdout: data['stdout']?.toString() ?? '',
          stderr: data['stderr']?.toString() ?? '',
          error: data['exception']?.toString() ?? '',
          executionTime: data['executionTime']?.toString() ?? '',
          memory: '', // OneCompiler doesn't always provide memory
        );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: ${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  Future<ExecutionResult> executeCustom(String code, CompilerPreset preset, {String stdin = ''}) async {
    try {
      // 1. Prepare Headers
      Map<String, String> requestHeaders = Map.from(preset.headers);

      // Handle Auth
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
         // Assuming authValue might be in format Key:Value
         var parts = preset.authValue.split(':');
         if (parts.length == 2) {
           requestHeaders[parts[0].trim()] = parts[1].trim();
         } else {
           requestHeaders['Authorization'] = preset.authValue; // fallback
         }
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        final encoded = base64Encode(utf8.encode(preset.authValue));
        requestHeaders['Authorization'] = 'Basic $encoded';
      }

      // 2. Prepare Query Params
      Map<String, String> qParams = Map.from(preset.queryParams);
      if (preset.authType == 'Query Param' && preset.authValue.isNotEmpty) {
         var parts = preset.authValue.split('=');
         if (parts.length == 2) {
           qParams[parts[0].trim()] = parts[1].trim();
         }
      }

      var uri = Uri.parse(preset.endpointUrl);
      if (qParams.isNotEmpty) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...qParams
        });
      }

      // 3. Prepare Body
      String bodyStr = preset.requestBodyTemplate;
      if (bodyStr.isNotEmpty) {
        // Simple replacements
        bodyStr = bodyStr.replaceAll('{language}', 'dart');
        bodyStr = bodyStr.replaceAll('{stdin}', stdin.replaceAll('\n', '\\n').replaceAll('"', '\\"'));

        // Code replacement safely
        String safeCode = jsonEncode(code);
        // remove the surrounding quotes from jsonEncode to place inside the template string
        if (safeCode.startsWith('"') && safeCode.endsWith('"')) {
          safeCode = safeCode.substring(1, safeCode.length - 1);
        }
        bodyStr = bodyStr.replaceAll('{code}', safeCode);
      }

      // 4. Execute
      http.Response response;
      if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: bodyStr.isNotEmpty ? bodyStr : null);
      } else {
        response = await http.post(uri, headers: requestHeaders, body: bodyStr.isNotEmpty ? bodyStr : null);
      }

      // 5. Parse Response
      if (response.statusCode >= 200 && response.statusCode < 300) {
         dynamic data;
         try {
           data = jsonDecode(response.body);
         } catch(e) {
           // Not JSON
           return ExecutionResult(
              stdout: response.body,
              stderr: '',
              error: '',
              executionTime: '',
              memory: ''
           );
         }

         return ExecutionResult(
           stdout: _extractValue(data, preset.stdoutPath) ?? '',
           stderr: _extractValue(data, preset.stderrPath) ?? '',
           error: _extractValue(data, preset.errorPath) ?? '',
           executionTime: _extractValue(data, preset.executionTimePath) ?? '',
           memory: _extractValue(data, preset.memoryPath) ?? '',
         );
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'HTTP Error: ${response.statusCode}',
          error: response.body,
          executionTime: '',
          memory: '',
        );
      }
    } catch (e) {
       return ExecutionResult(
        stdout: '',
        stderr: '',
        error: e.toString(),
        executionTime: '',
        memory: '',
      );
    }
  }

  String? _extractValue(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    var keys = path.split('.');
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
