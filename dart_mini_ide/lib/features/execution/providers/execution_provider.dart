import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => "");

class ExecutionState {
  final bool isLoading;
  final String? stdout;
  final String? stderr;
  final String? error;
  final String? executionTime;
  final String? memory;
  final bool hasRun;

  ExecutionState({
    this.isLoading = false,
    this.stdout,
    this.stderr,
    this.error,
    this.executionTime,
    this.memory,
    this.hasRun = false,
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    bool? hasRun,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      hasRun: hasRun ?? this.hasRun,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> runCode(String code, {CompilerPreset? preset, String? stdin}) async {
    state = state.copyWith(isLoading: true, hasRun: true, error: null, stdout: null, stderr: null);

    try {
      if (preset == null) {
        await _runOneCompiler(code, stdin);
      } else {
        await _runCustomCompiler(code, preset, stdin);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _runOneCompiler(String code, String? stdin) async {
    const url = 'https://onecompiler.com/api/code/exec';
    const apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      "language": "dart",
      "stdin": stdin ?? "",
      "files": [
        {
          "name": "main.dart",
          "content": code
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        state = state.copyWith(
          isLoading: false,
          stdout: data['stdout'],
          stderr: data['stderr'] ?? (data['exception'] != null ? data['exception'] : null),
          executionTime: data['executionTime']?.toString(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network Error: $e',
      );
    }
  }

  Future<void> _runCustomCompiler(String code, CompilerPreset preset, String? stdin) async {
    String bodyStr = preset.requestBodyTemplate;

    // Replace {code} with escaped content (without surrounding quotes)
    final encodedCode = jsonEncode(code);
    final contentOnly = encodedCode.substring(1, encodedCode.length - 1);

    bodyStr = bodyStr.replaceAll('{code}', contentOnly);
    bodyStr = bodyStr.replaceAll('{language}', 'dart');

    final encodedStdin = jsonEncode(stdin ?? "");
    final stdinOnly = encodedStdin.substring(1, encodedStdin.length - 1);
    bodyStr = bodyStr.replaceAll('{stdin}', stdinOnly);

    final headers = Map<String, String>.from(preset.headers);

    try {
      final response = await http.post(
        Uri.parse(preset.url),
        headers: headers,
        body: bodyStr
      );

       if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);

          state = state.copyWith(
            isLoading: false,
            stdout: _extractValue(data, preset.responseMapping['stdout'] ?? '') ?? 'No output',
            stderr: _extractValue(data, preset.responseMapping['stderr'] ?? ''),
            executionTime: _extractValue(data, preset.responseMapping['executionTime'] ?? ''),
          );
       } else {
         state = state.copyWith(
           isLoading: false,
           error: 'Error ${response.statusCode}: ${response.body}',
         );
       }

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String? _extractValue(dynamic data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
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
