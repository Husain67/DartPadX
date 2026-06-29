import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/compiler_preset.dart';
import 'preset_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
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

  Future<void> runCode(String code) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final presetState = ref.read(presetProvider);

    try {
      if (presetState.useDefaultCompiler) {
        await _runOneCompiler(code);
      } else {
        final activePresetId = presetState.activePresetId;
        if (activePresetId == null) {
          throw Exception("No custom preset selected.");
        }
        final preset = presetState.presets.firstWhere((p) => p.id == activePresetId);
        await _runCustomPreset(code, preset);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: e.toString());
    }
  }

  Future<void> _runOneCompiler(String code) async {
    const url = 'https://onecompiler-apis.p.rapidapi.com/api/v1/run';
    const apiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'; // As per request

    final headers = {
      'content-type': 'application/json',
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
    };

    final body = json.encode({
      "language": "dart",
      "stdin": "",
      "files": [
        {
          "name": "main.dart",
          "content": code
        }
      ]
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: resData['stdout'] ?? '',
        stderr: resData['stderr'] ?? ((resData['exception'] != null) ? resData['exception'] : ''),
        executionTime: resData['executionTime']?.toString() ?? '',
        memory: resData['memory'] != null ? '${resData['memory']} KB' : '',
      );
    } else {
      state = state.copyWith(isRunning: false, stderr: 'HTTP ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _runCustomPreset(String code, CompilerPreset preset) async {
    if (preset.endpointUrl.isEmpty) {
      throw Exception("Endpoint URL is empty.");
    }

    Uri uri = Uri.parse(preset.endpointUrl);

    Map<String, String> finalHeaders = Map.from(preset.headers);
    Map<String, String> finalQueryParams = Map.from(preset.queryParams);

    // Auth handling
    if (preset.authType == 'API-Key Header') {
      final parts = preset.authValue.split(':');
      if (parts.length >= 2) {
        finalHeaders[parts[0].trim()] = parts.sublist(1).join(':').trim();
      }
    } else if (preset.authType == 'Bearer Token') {
      finalHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      finalHeaders['Authorization'] = 'Basic $encoded';
    } else if (preset.authType == 'Query Param') {
       final parts = preset.authValue.split('=');
       if (parts.length >= 2) {
          finalQueryParams[parts[0].trim()] = parts.sublist(1).join('=').trim();
       }
    }

    if (finalQueryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: finalQueryParams);
    }

    String parsedBody = preset.bodyTemplate
      .replaceAll('{code}', _escapeJsonString(code))
      .replaceAll('{language}', 'dart')
      .replaceAll('{stdin}', '');

    http.Response response;

    if (preset.method.toUpperCase() == 'POST') {
       response = await http.post(uri, headers: finalHeaders, body: parsedBody);
    } else if (preset.method.toUpperCase() == 'PUT') {
       response = await http.put(uri, headers: finalHeaders, body: parsedBody);
    } else {
       response = await http.get(uri, headers: finalHeaders);
    }

    String out = '';
    String err = '';
    String time = '';
    String mem = '';

    try {
       final resData = json.decode(response.body);
       out = _getValueByPath(resData, preset.stdoutPath) ?? '';
       err = _getValueByPath(resData, preset.stderrPath) ?? '';
       if (err.isEmpty) {
         err = _getValueByPath(resData, preset.errorPath) ?? '';
       }
       time = _getValueByPath(resData, preset.timePath)?.toString() ?? '';
       mem = _getValueByPath(resData, preset.memoryPath)?.toString() ?? '';
    } catch (_) {
       // Fallback for non-JSON or parsing error
       out = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      state = state.copyWith(isRunning: false, stdout: out, stderr: err, executionTime: time, memory: mem);
    } else {
      state = state.copyWith(isRunning: false, stderr: 'HTTP ${response.statusCode}: $err\n${response.body}');
    }
  }

  String _escapeJsonString(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\r', '\\r').replaceAll('\t', '\\t');
  }

  dynamic _getValueByPath(dynamic map, String path) {
    if (path.isEmpty || map == null) return null;
    final keys = path.split('.');
    dynamic current = map;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current;
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
