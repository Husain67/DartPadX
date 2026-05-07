import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final bool isLoading;
  final String rawResponse;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.isLoading = false,
    this.rawResponse = '',
  });

  ExecutionResult copyWith({
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    bool? isLoading,
    String? rawResponse,
  }) {
    return ExecutionResult(
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      isLoading: isLoading ?? this.isLoading,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }

  void clear() {}
}

class ExecutionNotifier extends StateNotifier<ExecutionResult> {
  ExecutionNotifier() : super(ExecutionResult());

  void clear() {
    state = ExecutionResult();
  }

  Future<void> executeCode({
    required String code,
    required String stdin,
    required SettingsState settingsState,
  }) async {
    state = state.copyWith(isLoading: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '', rawResponse: '');

    CompilerPreset? preset;

    if (settingsState.useDefaultOneCompiler) {
        preset = settingsState.presets.firstWhere(
          (p) => p.isDefault,
          orElse: () => settingsState.presets.first,
        );
    } else {
        preset = settingsState.activePreset;
    }

    if (preset == null) {
      state = state.copyWith(isLoading: false, error: 'No compiler preset selected.');
      return;
    }

    try {
      final uri = Uri.parse(preset.endpointUrl);
      Map<String, String> headers = {};

      // Add custom headers
      for (var h in preset.headers) {
        if (h.key.isNotEmpty) {
          headers[h.key] = h.value;
        }
      }

      // Handle Auth
      if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
        headers[preset.authKey] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
         final encoded = base64Encode(utf8.encode(preset.authValue));
         headers['Authorization'] = 'Basic $encoded';
      }

      // Build Query Params
      Map<String, String> qParams = {};
      for (var q in preset.queryParams) {
         if (q.key.isNotEmpty) {
             qParams[q.key] = q.value;
         }
      }
      if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
         qParams[preset.authKey] = preset.authValue;
      }

      final requestUri = qParams.isNotEmpty ? uri.replace(queryParameters: qParams) : uri;

      // Build Body
      String body = preset.requestBodyTemplate;

      // Use proper JSON encoding for replacing content to prevent breaking JSON structure
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1); // remove outer quotes

      String encodedStdin = jsonEncode(stdin);
      encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      body = body.replaceAll('{code}', encodedCode);
      body = body.replaceAll('{stdin}', encodedStdin);
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      final startTime = DateTime.now();

      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(requestUri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(requestUri, headers: headers, body: body);
      } else {
        response = await http.post(requestUri, headers: headers, body: body);
      }

      final endTime = DateTime.now();
      final ms = endTime.difference(startTime).inMilliseconds;

      final rawResponse = response.body;

      String stdout = '';
      String stderr = '';
      String error = '';
      String execTime = '${ms}ms';
      String memory = '';

      if (response.statusCode >= 200 && response.statusCode < 300) {
         try {
           final jsonResponse = jsonDecode(response.body);

           stdout = _extractValue(jsonResponse, preset.stdoutPath);
           stderr = _extractValue(jsonResponse, preset.stderrPath);

           final parsedError = _extractValue(jsonResponse, preset.errorPath);
           if (parsedError.isNotEmpty) {
             error = parsedError;
           }

           final parsedTime = _extractValue(jsonResponse, preset.executionTimePath);
           if (parsedTime.isNotEmpty) {
             execTime = '${parsedTime}ms';
           }

           memory = _extractValue(jsonResponse, preset.memoryPath);

         } catch (e) {
           stdout = response.body; // Fallback if not JSON
         }
      } else {
         error = 'HTTP ${response.statusCode}: ${response.body}';
      }

      state = state.copyWith(
        isLoading: false,
        stdout: stdout,
        stderr: stderr,
        error: error,
        executionTime: execTime,
        memory: memory,
        rawResponse: rawResponse,
      );

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network or Execution Error: $e',
      );
    }
  }

  String _extractValue(dynamic data, String path) {
    if (path.isEmpty) return '';
    try {
      final parts = path.split('.');
      dynamic current = data;
      for (var part in parts) {
        if (current == null) return '';
        if (current is Map) {
          current = current[part];
        } else if (current is List) {
           int? index = int.tryParse(part);
           if (index != null && index >= 0 && index < current.length) {
              current = current[index];
           } else {
              return '';
           }
        } else {
          return '';
        }
      }
      return current?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionResult>((ref) {
  return ExecutionNotifier();
});

// A simple provider for stdin input string
final stdinProvider = StateProvider<String>((ref) => '');
