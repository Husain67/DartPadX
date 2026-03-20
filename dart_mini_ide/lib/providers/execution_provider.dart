import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String rawResponse;

  ExecutionState({
    required this.isRunning,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
    required this.rawResponse,
  });

  factory ExecutionState.initial() => ExecutionState(
        isRunning: false,
        stdout: '',
        stderr: '',
        executionTime: '',
        memory: '',
        rawResponse: '',
      );

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? rawResponse,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState.initial());

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '', rawResponse: '');
  }

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider);
    final compilerState = ref.read(compilerProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '', rawResponse: '');

    try {
      if (compilerState.useDefault || compilerState.activePreset == null) {
        await _executeDefault(activeFile.content);
      } else {
        await _executeCustom(compilerState.activePreset!, activeFile.content);
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Error: $e',
      );
    }
  }

  Future<void> _executeDefault(String code) async {
    final apiKey = const String.fromEnvironment('ONECOMPILER_KEY',
        defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

    final response = await http.post(
      Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'),
      headers: {
        'content-type': 'application/json',
        'x-rapidapi-key': apiKey,
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": "",
        "files": [
          {"name": "index.dart", "content": code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: jsonResponse['stdout'] ?? '',
        stderr: jsonResponse['stderr'] ?? jsonResponse['exception'] ?? '',
        executionTime: jsonResponse['executionTime'].toString() + ' ms',
        memory: jsonResponse['memory'].toString() + ' bytes',
        rawResponse: response.body,
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution failed: ${response.statusCode} - ${response.body}',
        rawResponse: response.body,
      );
    }
  }

  Future<void> _executeCustom(CompilerPreset preset, String code) async {
    final url = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams);
    final headers = preset.headers;
    final body = preset.bodyTemplate
        .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{language}', 'dart');

    http.Response response;
    if (preset.httpMethod == 'POST') {
      response = await http.post(url, headers: headers, body: body);
    } else if (preset.httpMethod == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(url, headers: headers, body: body);
    } else {
      throw Exception('Unsupported HTTP method: ${preset.httpMethod}');
    }

    final String rawBody = response.body;
    state = state.copyWith(rawResponse: rawBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonResponse = jsonDecode(rawBody);
      state = state.copyWith(
        isRunning: false,
        stdout: _resolvePath(jsonResponse, preset.stdoutPath),
        stderr: _resolvePath(jsonResponse, preset.stderrPath) ?? _resolvePath(jsonResponse, preset.errorPath),
        executionTime: _resolvePath(jsonResponse, preset.executionTimePath) ?? '',
        memory: _resolvePath(jsonResponse, preset.memoryPath) ?? '',
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution failed: ${response.statusCode} - $rawBody',
      );
    }
  }

  String? _resolvePath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic value = json;
    for (var key in keys) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value.toString();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
