import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode(String code) async {
    state = ExecutionState(isExecuting: true);

    final settings = ref.read(settingsProvider);

    if (settings.useDefaultOneCompiler) {
      await _executeOneCompiler(code);
    } else {
      if (settings.activePresetId == null) {
        state = state.copyWith(isExecuting: false, error: 'No active custom preset selected.');
        return;
      }
      final preset = settings.presets.firstWhere((p) => p.id == settings.activePresetId, orElse: () => throw Exception('Preset not found'));
      await _executeCustomPreset(code, preset);
    }
  }

  Future<void> _executeOneCompiler(String code) async {
     const apiKey = String.fromEnvironment('RAPID_API_KEY');
     if (apiKey.isEmpty) {
        state = ExecutionState(
          isExecuting: false,
          error: 'Execution failed: RAPID_API_KEY environment variable is not set.'
        );
        return;
     }

     try {
       final response = await http.post(
         Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'),
         headers: {
           'Content-Type': 'application/json',
           'X-RapidAPI-Key': apiKey,
           'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
         },
         body: jsonEncode({
           'language': 'dart',
           'stdin': '',
           'files': [
             {
               'name': 'main.dart',
               'content': code
             }
           ]
         })
       );

       if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         state = ExecutionState(
           isExecuting: false,
           stdout: data['stdout'] ?? '',
           stderr: data['stderr'] ?? '',
           error: data['exception'] ?? '',
           executionTime: data['executionTime']?.toString() ?? '',
           memory: ''
         );
       } else {
          state = ExecutionState(
            isExecuting: false,
            error: 'HTTP Error: \${response.statusCode}\\n\${response.body}'
          );
       }
     } catch(e) {
         state = ExecutionState(
            isExecuting: false,
            error: 'Execution failed: \$e'
          );
     }
  }

  Future<void> _executeCustomPreset(String code, dynamic preset) async {
      try {
        final uri = Uri.parse(preset.endpointUrl);
        Map<String, String> finalHeaders = Map.from(preset.headers);

        if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
           // Assume standard Authorization header if not mapped in headers map
           if (!finalHeaders.containsKey('Authorization')) {
              finalHeaders['Authorization'] = preset.authValue;
           }
        } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
           finalHeaders['Authorization'] = 'Bearer \${preset.authValue}';
        } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
           final encoded = base64Encode(utf8.encode(preset.authValue));
           finalHeaders['Authorization'] = 'Basic $encoded';
        }

        // Apply query params
        final uriWithQuery = uri.replace(queryParameters: {
           ...uri.queryParameters,
           ...preset.queryParams,
        });

        // Template Body
        String finalBody = preset.requestBodyTemplate;
        final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
        finalBody = finalBody.replaceAll('{code}', safeCode);
        finalBody = finalBody.replaceAll('{language}', 'dart');
        finalBody = finalBody.replaceAll('{stdin}', '');

        http.Response response;
        if (preset.httpMethod == 'POST') {
          response = await http.post(uriWithQuery, headers: finalHeaders, body: finalBody);
        } else if (preset.httpMethod == 'PUT') {
           response = await http.put(uriWithQuery, headers: finalHeaders, body: finalBody);
        } else {
           response = await http.get(uriWithQuery, headers: finalHeaders);
        }

        final dynamic data = jsonDecode(response.body);

        String getVal(dynamic obj, String path) {
           if (path.isEmpty) return '';
           final parts = path.split('.');
           dynamic current = obj;
           for (var part in parts) {
              if (current is Map && current.containsKey(part)) {
                 current = current[part];
              } else {
                 return '';
              }
           }
           return current?.toString() ?? '';
        }

        state = ExecutionState(
          isExecuting: false,
          stdout: getVal(data, preset.stdoutPath),
          stderr: getVal(data, preset.stderrPath),
          error: getVal(data, preset.errorPath),
          executionTime: getVal(data, preset.executionTimePath),
          memory: getVal(data, preset.memoryPath),
        );

      } catch (e) {
         state = ExecutionState(
            isExecuting: false,
            error: 'Custom execution failed: \$e'
          );
      }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
