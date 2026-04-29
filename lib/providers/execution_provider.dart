import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
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

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> runCode(String code, String stdin) async {
    state = ExecutionState(isRunning: true);

    final settings = ref.read(settingsProvider);

    try {
      if (settings.useDefaultOneCompiler) {
        await _runDefaultOneCompiler(code, stdin);
      } else {
        await _runCustomPreset(code, stdin, settings);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  Future<void> _runDefaultOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'X-RapidAPI-Key': String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM=')),
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
      state = state.copyWith(
        isRunning: false,
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? '',
        error: data['exception'] ?? '',
        executionTime: '${data['executionTime'] ?? 0} ms',
      );
    } else {
      state = state.copyWith(isRunning: false, error: 'Failed: ${response.statusCode}');
    }
  }

  Future<void> _runCustomPreset(String code, String stdin, SettingsState settings) async {
    final preset = settings.presets.firstWhere(
      (p) => p.id == settings.activePresetId,
      orElse: () => throw Exception('No active preset selected'),
    );

    if (preset.endpoint.isEmpty) throw Exception('Endpoint URL is empty');

    final uri = Uri.parse(preset.endpoint);
    final headers = <String, String>{};
    for (var entry in preset.headers) {
      headers[entry.key] = entry.value;
    }

    if (preset.authType == 'Header') {
      headers['Authorization'] = preset.authValue;
    } else if (preset.authType == 'Bearer') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic') {
      headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
    }

    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', _escapeForJson(code))
        .replaceAll('{stdin}', _escapeForJson(stdin))
        .replaceAll('{language}', 'dart');

    http.Response response;
    if (preset.httpMethod == 'POST') {
      response = await http.post(uri, headers: headers, body: bodyStr);
    } else {
      response = await http.get(uri, headers: headers);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: _resolvePath(data, preset.stdoutPath),
        stderr: _resolvePath(data, preset.stderrPath),
        error: _resolvePath(data, preset.errorPath),
        executionTime: _resolvePath(data, preset.timePath),
        memory: _resolvePath(data, preset.memoryPath),
      );
    } else {
      state = state.copyWith(isRunning: false, error: 'HTTP ${response.statusCode}: ${response.body}');
    }
  }

  String _escapeForJson(String input) {
    return jsonEncode(input).replaceAll(RegExp(r'^"|"$'), '');
  }

  String _resolvePath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return '';
    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => '');
