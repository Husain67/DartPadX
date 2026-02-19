import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'settings_provider.dart';

class CompilationResult {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final bool isError;

  CompilationResult({
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.isError = false,
  });
}

class CompilerState {
  final bool isLoading;
  final CompilationResult? result;

  CompilerState({this.isLoading = false, this.result});
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Ref ref;

  CompilerNotifier(this.ref) : super(CompilerState());

  Future<void> runCode(String code, String stdin) async {
    state = CompilerState(isLoading: true, result: null);

    final settings = ref.read(settingsProvider);
    final preset = settings.activePreset;

    try {
      if (preset == null) {
        await _runOneCompiler(code, stdin);
      } else {
        await _runCustomCompiler(preset, code, stdin);
      }
    } catch (e) {
      state = CompilerState(
        isLoading: false,
        result: CompilationResult(stderr: 'Error: $e', isError: true),
      );
    }
  }

  Future<void> _runOneCompiler(String code, String stdin) async {
    try {
     final response = await http.post(
       Uri.parse('https://onecompiler.com/api/v1/run'),
       headers: {
         'Content-Type': 'application/json',
         'Authorization': 'Bearer oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'
       },
       body: jsonEncode({
         "language": "dart",
         "files": [
           {"name": "main.dart", "content": code}
         ],
         "stdin": stdin
       }),
     );

     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);
       state = CompilerState(
         isLoading: false,
         result: CompilationResult(
           stdout: data['stdout'] ?? '',
           stderr: data['stderr'] ?? (data['exception'] ?? ''),
           executionTime: '${data['executionTime'] ?? 0}ms',
           memory: '',
           isError: (data['stderr'] != null && data['stderr'].isNotEmpty) || data['exception'] != null,
         ),
       );
     } else {
       throw Exception('OneCompiler Error: ${response.statusCode} ${response.body}');
     }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _runCustomCompiler(CompilerPreset preset, String code, String stdin) async {
    try {
      // Replace placeholders
      // Use simpler replacement for now, robust template engine would be better but simple string replace is what was asked
      String body = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1)) // escaped
          .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
          .replaceAll('{language}', 'dart');

      // Headers
      final headers = Map<String, String>.from(preset.headers);

      // Request
      http.Response response;

      // Construct URI with query params
      final uri = Uri.parse(preset.endpoint).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      if (preset.method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        throw Exception('Unsupported method: ${preset.method}');
      }

      // Parse Response
      final data = jsonDecode(response.body);

      dynamic getValue(dynamic json, String path) {
         if (path.isEmpty) return null;
         final parts = path.split('.');
         dynamic current = json;
         for (final part in parts) {
           if (current is Map && current.containsKey(part)) {
             current = current[part];
           } else {
             return null;
           }
         }
         return current?.toString();
      }

      state = CompilerState(
        isLoading: false,
        result: CompilationResult(
          stdout: getValue(data, preset.responseMapping['stdout'] ?? '') ?? '',
          stderr: getValue(data, preset.responseMapping['stderr'] ?? '') ?? '',
          executionTime: getValue(data, preset.responseMapping['executionTime'] ?? '') ?? '',
          memory: getValue(data, preset.responseMapping['memory'] ?? '') ?? '',
          isError: (getValue(data, preset.responseMapping['error'] ?? '') != null),
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref);
});
