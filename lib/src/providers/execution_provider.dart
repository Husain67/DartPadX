import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_provider.dart';

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;
  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin) async {
    state = ExecutionState(isLoading: true);

    final compilerState = ref.read(compilerProvider);
    CompilerPreset? preset;

    if (compilerState.useDefaultOneCompiler) {
      preset = CompilerPreset(
        name: 'Default OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        mappings: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': 'memory',
        },
      );
    } else {
      if (compilerState.selectedPresetId == null) {
        state = ExecutionState(stderr: 'No compiler preset selected.');
        return;
      }
      preset = compilerState.presets.firstWhere((p) => p.id == compilerState.selectedPresetId);
    }

    try {
      final headers = Map<String, String>.from(preset.headers);
      if (!headers.containsKey('Content-Type')) {
        headers['Content-Type'] = 'application/json';
      }

      if (preset.authType == 'API-Key Header') {
        headers['Authorization'] = preset.authValue;
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      String uriStr = preset.url;
      if (preset.queryParams.isNotEmpty || (preset.authType == 'Query Param')) {
         final query = Map<String, String>.from(preset.queryParams);
         if(preset.authType == 'Query Param' && preset.authValue.contains('=')){
            final parts = preset.authValue.split('=');
            query[parts[0]] = parts[1];
         }
         final uri = Uri.parse(uriStr).replace(queryParameters: query);
         uriStr = uri.toString();
      }

      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      final escapedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');
      final body = preset.bodyTemplate
          .replaceAll('{code}', escapedCode)
          .replaceAll('{stdin}', escapedStdin)
          .replaceAll('{language}', 'dart');

      final requestUri = Uri.parse(uriStr);
      http.Response response;

      final startTime = DateTime.now();
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(requestUri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(requestUri, headers: headers, body: body);
      } else {
        response = await http.get(requestUri, headers: headers);
      }
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String getNestedValue(Map<String, dynamic> obj, String path) {
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

        final stdout = getNestedValue(data, preset.mappings['stdout'] ?? '');
        final stderr = getNestedValue(data, preset.mappings['stderr'] ?? '');
        final error = getNestedValue(data, preset.mappings['error'] ?? '');
        final execTime = getNestedValue(data, preset.mappings['executionTime'] ?? '');
        final memory = getNestedValue(data, preset.mappings['memory'] ?? '');

        final finalStderr = [stderr, error].where((e) => e.isNotEmpty).join('\n');

        state = ExecutionState(
          stdout: stdout,
          stderr: finalStderr,
          executionTime: execTime.isNotEmpty ? execTime : '${duration}ms',
          memory: memory,
        );
      } else {
        state = ExecutionState(stderr: 'HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      state = ExecutionState(stderr: 'Execution Exception: $e');
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => '');
