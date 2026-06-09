import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin, CompilerPreset? preset) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      if (preset == null || preset.id == 'default_oc') {
        await _executeOneCompiler(code, stdin);
      } else {
        await _executeCustomPreset(code, stdin, preset);
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Execution Error: $e',
      );
    }
  }

  Future<void> _executeOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
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
        isExecuting: false,
        stdout: data['stdout']?.toString() ?? '',
        stderr: data['stderr']?.toString() ?? (data['exception']?.toString() ?? ''),
        executionTime: data['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'OneCompiler API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> _executeCustomPreset(String code, String stdin, CompilerPreset preset) async {
    // Basic dynamic params replacement
    String endpointUrl = preset.endpointUrl;

    // Auth Headers
    Map<String, String> requestHeaders = Map.from(preset.headers);
    if (preset.authType == 'API-Key Header') {
       // Usually mapped via headers UI already, but fallback here
    } else if (preset.authType == 'Bearer Token') {
       // Assuming token is in headers map as 'Authorization'
    }

    String requestBody = preset.requestBodyTemplate
        .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{stdin}', jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{language}', 'dart');

    http.Response response;
    final uri = Uri.parse(endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(uri, headers: requestHeaders);
    } else if (preset.method.toUpperCase() == 'PUT') {
      response = await http.put(uri, headers: requestHeaders, body: requestBody);
    } else {
      response = await http.post(uri, headers: requestHeaders, body: requestBody);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch(e) {
        data = response.body;
      }

      String parsedStdout = _extractPath(data, preset.stdoutPath) ?? '';
      String parsedStderr = _extractPath(data, preset.stderrPath) ?? '';
      String parsedError = _extractPath(data, preset.errorPath) ?? '';
      String parsedTime = _extractPath(data, preset.executionTimePath) ?? '';
      String parsedMemory = _extractPath(data, preset.memoryPath) ?? '';

      state = state.copyWith(
        isExecuting: false,
        stdout: parsedStdout,
        stderr: parsedStderr.isNotEmpty ? parsedStderr : parsedError,
        executionTime: parsedTime,
        memory: parsedMemory,
      );
    } else {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  String? _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return null;
    if (data is String) return data; // fallback
    List<String> keys = path.split('.');
    dynamic current = data;
    for (String key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

// A simple provider for standard input
final stdinProvider = StateProvider<String>((ref) => '');

// Provide the list of available presets and the selected one
final presetsProvider = StateNotifierProvider<PresetsNotifier, List<CompilerPreset>>((ref) {
  return PresetsNotifier();
});

final activePresetProvider = StateProvider<CompilerPreset?>((ref) {
  final presets = ref.watch(presetsProvider);
  try {
     return presets.firstWhere((p) => p.isDefault);
  } catch(e) {
     return null; // meaning default OneCompiler
  }
});

class PresetsNotifier extends StateNotifier<List<CompilerPreset>> {
  late Box<CompilerPreset> _box;

  PresetsNotifier() : super([]) {
    _init();
  }

  void _init() {
    _box = Hive.box<CompilerPreset>('presets');
    if (_box.isEmpty) {
      // Default OneCompiler
      final defaultOc = CompilerPreset(
        id: 'default_oc',
        name: 'OneCompiler (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        isDefault: true,
      );
      // Other placeholders
      final jdoodle = CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        requestBodyTemplate: '{\n  "clientId": "",\n  "clientSecret": "",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory'
      );

       final piston = CompilerPreset(
        id: 'piston',
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      );

      _box.put(defaultOc.id, defaultOc);
      _box.put(jdoodle.id, jdoodle);
      _box.put(piston.id, piston);
      state = [defaultOc, jdoodle, piston];
    } else {
      state = _box.values.toList();
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }

  void setDefault(String id) {
    for (var preset in state) {
      final updated = preset.copyWith(isDefault: preset.id == id);
      _box.put(preset.id, updated);
    }
    state = _box.values.toList();
  }
}
