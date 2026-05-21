import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset_model.dart';
import 'preset_provider.dart';

final stdinProvider = StateProvider<String>((ref) => '');

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionState({
    required this.isRunning,
    required this.stdout,
    required this.stderr,
    required this.time,
    required this.memory,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref)
      : super(ExecutionState(
          isRunning: false,
          stdout: '',
          stderr: '',
          time: '',
          memory: '',
        ));

  void clearOutput() {
    state = ExecutionState(
      isRunning: false,
      stdout: '',
      stderr: '',
      time: '',
      memory: '',
    );
  }

  Future<void> runCode(String code) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', time: '', memory: '');

    final presetNotifier = ref.read(presetProvider.notifier);
    final useDefault = ref.read(presetProvider).useDefaultOneCompiler;
    final stdin = ref.read(stdinProvider);

    try {
      if (useDefault) {
        await _runDefaultOneCompiler(code, stdin);
      } else {
        final activePreset = presetNotifier.activePreset;
        if (activePreset != null) {
          await _runCustomPreset(code, stdin, activePreset);
        } else {
          state = state.copyWith(isRunning: false, stderr: 'No custom preset selected.');
        }
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Execution failed: \$e');
    }
  }

  Future<void> _runDefaultOneCompiler(String code, String stdin) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    final headers = {
      'x-rapidapi-key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
      'Content-Type': 'application/json'
    };

    final body = jsonEncode({
      "language": "dart",
      "stdin": stdin,
      "files": [
        {"name": "main.dart", "content": code}
      ]
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: json['stdout']?.toString() ?? '',
        stderr: json['stderr']?.toString() ?? json['exception']?.toString() ?? '',
        time: json['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(isRunning: false, stderr: 'HTTP Error \${response.statusCode}: \${response.body}');
    }
  }

  Future<void> _runCustomPreset(String code, String stdin, CompilerPresetModel preset) async {
    // 1. Prepare URL and Query Params
    var urlString = preset.url;
    if (preset.queryParams.isNotEmpty) {
      final uri = Uri.parse(urlString);
      urlString = uri.replace(queryParameters: preset.queryParams).toString();
    }
    final uri = Uri.parse(urlString);

    // 2. Prepare Headers
    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
       // Assuming user put the token in headers if they selected Bearer but didn't build it.
       // For a real app, you might have a dedicated token field. We use the headers map for simplicity.
    }

    // 3. Prepare Body
    String bodyString = preset.requestBodyTemplate;

    // Safely encode code and stdin for JSON string placement without wrapping in extra quotes
    String safeCode = jsonEncode(code);
    safeCode = safeCode.substring(1, safeCode.length - 1); // remove surrounding quotes

    String safeStdin = jsonEncode(stdin);
    safeStdin = safeStdin.substring(1, safeStdin.length - 1);

    bodyString = bodyString.replaceAll('{code}', safeCode);
    bodyString = bodyString.replaceAll('{stdin}', safeStdin);
    bodyString = bodyString.replaceAll('{language}', 'dart');

    http.Response response;

    try {
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyString);
      } else {
        // Default to POST
        response = await http.post(uri, headers: headers, body: bodyString);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
         try {
            final json = jsonDecode(response.body);
            state = state.copyWith(
              isRunning: false,
              stdout: _extractValue(json, preset.outputMappingPath) ?? '',
              stderr: _extractValue(json, preset.errorMappingPath) ?? '',
              time: _extractValue(json, preset.executionTimeMappingPath) ?? '',
              memory: _extractValue(json, preset.memoryMappingPath) ?? '',
            );
         } catch(e) {
            // Not JSON
            state = state.copyWith(isRunning: false, stdout: response.body);
         }
      } else {
         state = state.copyWith(isRunning: false, stderr: 'HTTP Error \${response.statusCode}: \${response.body}');
      }
    } catch (e) {
       state = state.copyWith(isRunning: false, stderr: 'Request failed: \$e');
    }
  }

  String? _extractValue(dynamic data, String path) {
    if (path.isEmpty) return null;
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}
