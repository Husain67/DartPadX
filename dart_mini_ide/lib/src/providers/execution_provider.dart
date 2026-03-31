import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
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
  final bool showOutput;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    bool? showOutput,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      showOutput: showOutput ?? this.showOutput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void hideOutput() {
    state = state.copyWith(showOutput: false);
  }

  void clearOutput() {
    state = ExecutionState(showOutput: true);
  }

  Future<void> executeCode(String code) async {
    state = state.copyWith(
      isExecuting: true,
      stdout: '',
      stderr: '',
      error: '',
      executionTime: '',
      memory: '',
      showOutput: true,
    );

    final settings = ref.read(settingsProvider);
    final useDefault = settings.useDefaultApi;
    final customPresetId = settings.selectedPresetId;

    try {
      if (useDefault) {
        await _executeOneCompiler(code);
      } else {
        if (customPresetId == null) {
          throw Exception("No custom preset selected.");
        }
        final presets = ref.read(presetsProvider);
        final preset = presets.firstWhere((p) => p.id == customPresetId);
        await _executeCustom(code, preset);
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: "Execution Failed:\n$e",
      );
    }
  }

  Future<void> _executeOneCompiler(String code) async {
    // Default OneCompiler configuration as per requirements
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": "",
        "files": [
          {
            "name": "main.dart",
            "content": code
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isExecuting: false,
        stdout: json['stdout'] ?? '',
        stderr: json['stderr'] ?? '',
        error: json['exception'] ?? '',
        executionTime: json['executionTime']?.toString() ?? '',
        memory: '', // Not provided typically
      );
    } else {
      throw Exception("OneCompiler API Error: ${response.statusCode}\n${response.body}");
    }
  }

  Future<void> _executeCustom(String code, CompilerPreset preset) async {
    final uri = Uri.parse(preset.endpointUrl);

    // Prepare headers
    final Map<String, String> finalHeaders = {...preset.headers};
    if (preset.authType == 'API-Key Header') {
      final parts = preset.authValue.split(':');
      if (parts.length == 2) {
        finalHeaders[parts[0]] = parts[1];
      }
    } else if (preset.authType == 'Bearer Token') {
      finalHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final auth = base64Encode(utf8.encode(preset.authValue));
      finalHeaders['Authorization'] = 'Basic $auth';
    }

    // Build Request
    late http.Response response;

    // Process body template
    // Replace {code} properly maintaining JSON encoding if it's inside quotes
    // For a robust replacement, we encode code as json and strip the outer quotes
    final codeJsonEscaped = jsonEncode(code);
    final codeStripped = codeJsonEscaped.substring(1, codeJsonEscaped.length - 1);

    String finalBody = preset.requestBodyTemplate
        .replaceAll('{code}', codeStripped)
        .replaceAll('{language}', 'dart')
        .replaceAll('{stdin}', '');

    final requestUri = uri.replace(queryParameters: preset.queryParams.isEmpty ? null : preset.queryParams);

    if (preset.httpMethod == 'POST') {
      response = await http.post(requestUri, headers: finalHeaders, body: finalBody);
    } else if (preset.httpMethod == 'GET') {
      response = await http.get(requestUri, headers: finalHeaders);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(requestUri, headers: finalHeaders, body: finalBody);
    } else {
      throw Exception("Unsupported HTTP Method");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isExecuting: false,
        stdout: _getValueFromDotPath(json, preset.stdoutPath) ?? '',
        stderr: _getValueFromDotPath(json, preset.stderrPath) ?? '',
        error: _getValueFromDotPath(json, preset.errorPath) ?? '',
        executionTime: _getValueFromDotPath(json, preset.executionTimePath) ?? '',
        memory: _getValueFromDotPath(json, preset.memoryPath) ?? '',
      );
    } else {
      throw Exception("Custom API Error: ${response.statusCode}\n${response.body}");
    }
  }

  String? _getValueFromDotPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;
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
