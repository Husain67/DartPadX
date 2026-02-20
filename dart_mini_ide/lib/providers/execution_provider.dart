import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error; // System/Network errors
  final String executionTime;
  final String memory;
  final bool isSuccess;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.isSuccess = false,
  });
}

final executionResultProvider = StateProvider<ExecutionResult?>((ref) => null);
final isExecutingProvider = StateProvider<bool>((ref) => false);

final executionProvider = Provider((ref) => ExecutionService(ref));

class ExecutionService {
  final Ref ref;

  ExecutionService(this.ref);

  Future<void> runCode(String code, String stdin) async {
    final preset = ref.read(activePresetProvider);
    if (preset == null) {
      ref.read(executionResultProvider.notifier).state = ExecutionResult(error: 'No compiler preset selected');
      return;
    }

    ref.read(isExecutingProvider.notifier).state = true;
    ref.read(executionResultProvider.notifier).state = null;

    try {
      final client = http.Client();

      // Escape for JSON string value manually to ensure it fits in template
      // jsonEncode adds surrounding quotes, remove them
      String escapedCode = jsonEncode(code);
      escapedCode = escapedCode.substring(1, escapedCode.length - 1);

      String escapedStdin = jsonEncode(stdin);
      escapedStdin = escapedStdin.substring(1, escapedStdin.length - 1);

      String body = preset.requestBodyTemplate
          .replaceAll('{code}', escapedCode)
          .replaceAll('{stdin}', escapedStdin)
          .replaceAll('{language}', 'dart');

      // Map Headers
      Map<String, String> headers = Map.from(preset.headers);

      // Construct URI
      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams);

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await client.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod == 'GET') {
         response = await client.get(uri, headers: headers);
      } else if (preset.httpMethod == 'PUT') {
         response = await client.put(uri, headers: headers, body: body);
      } else {
         response = await client.post(uri, headers: headers, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = jsonDecode(response.body);

        // Parse result using dot notation
        String stdout = _getValue(jsonResponse, preset.stdoutPath) ?? '';
        String stderr = _getValue(jsonResponse, preset.stderrPath) ?? '';
        String error = _getValue(jsonResponse, preset.errorPath) ?? '';
        String time = _getValue(jsonResponse, preset.executionTimePath) ?? '';
        String memory = _getValue(jsonResponse, preset.memoryPath) ?? '';

        ref.read(executionResultProvider.notifier).state = ExecutionResult(
          stdout: stdout,
          stderr: stderr,
          error: error,
          executionTime: time,
          memory: memory,
          isSuccess: true,
        );

      } else {
         ref.read(executionResultProvider.notifier).state = ExecutionResult(
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }

    } catch (e) {
      ref.read(executionResultProvider.notifier).state = ExecutionResult(
        error: 'Execution failed: $e',
      );
    } finally {
      ref.read(isExecutingProvider.notifier).state = false;
    }
  }

  String? _getValue(dynamic json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;

    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List) {
         // Handle list index if key is integer
         int? index = int.tryParse(key);
         if (index != null && index >= 0 && index < current.length) {
            current = current[index];
         } else {
            return null;
         }
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
