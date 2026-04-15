import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';
import 'preset_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

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

  Future<void> executeCode(String code, {String stdin = ''}) async {
    final settings = ref.read(settingsProvider);
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    try {
      if (settings.useDefaultOneCompiler) {
        await _runOneCompiler(code, stdin);
      } else {
        final presetId = settings.selectedPresetId;
        if (presetId == null || presetId.isEmpty) {
          throw Exception('No Custom Preset Selected');
        }
        final preset = ref.read(presetProvider).firstWhere((p) => p.id == presetId, orElse: () => throw Exception('Preset not found'));
        await _runCustomPreset(preset, code, stdin);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  Future<void> _runOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
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
      final json = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: json['stdout']?.toString() ?? '',
        stderr: json['stderr']?.toString() ?? '',
        error: json['exception']?.toString() ?? '',
        executionTime: json['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        error: 'Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> _runCustomPreset(dynamic preset, String code, String stdin) async {
    // Process Auth and Headers
    final Map<String, String> finalHeaders = Map.from(preset.headers);
    if (preset.authType == 'Bearer Token' && preset.authValue != null) {
      finalHeaders['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
      final encoded = base64Encode(utf8.encode(preset.authValue!));
      finalHeaders['Authorization'] = 'Basic $encoded';
    } else if (preset.authType == 'API-Key Header' && preset.authValue != null) {
      // Replace {authValue} placeholder in headers if present
      finalHeaders.forEach((key, value) {
        if (value.contains('{authValue}')) {
          finalHeaders[key] = value.replaceAll('{authValue}', preset.authValue!);
        }
      });
    }

    // Process Query Params
    var uri = Uri.parse(preset.endpointUrl);
    if (preset.queryParams.isNotEmpty) {
      final queryParams = Map<String, dynamic>.from(uri.queryParameters);
      queryParams.addAll(preset.queryParams);
      if (preset.authType == 'Query Param' && preset.authValue != null) {
         // Assuming user set a specific key or we just append it (simplification: user maps it in preset UI)
      }
      uri = uri.replace(queryParameters: queryParams);
    }

    // Process Body
    String bodyContent = preset.bodyTemplate;
    // properly escape JSON code string if body is JSON
    final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final escapedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

    bodyContent = bodyContent.replaceAll('{code}', escapedCode);
    bodyContent = bodyContent.replaceAll('{stdin}', escapedStdin);
    bodyContent = bodyContent.replaceAll('{language}', 'dart');

    http.Response response;
    if (preset.httpMethod == 'GET') {
      response = await http.get(uri, headers: finalHeaders);
    } else if (preset.httpMethod == 'PUT') {
      response = await http.put(uri, headers: finalHeaders, body: bodyContent);
    } else {
      response = await http.post(uri, headers: finalHeaders, body: bodyContent);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      dynamic jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } catch (_) {
        jsonResponse = response.body; // text response
      }

      state = state.copyWith(
        isRunning: false,
        stdout: _extractPath(jsonResponse, preset.stdoutPath),
        stderr: _extractPath(jsonResponse, preset.stderrPath),
        error: _extractPath(jsonResponse, preset.errorPath),
        executionTime: _extractPath(jsonResponse, preset.executionTimePath),
        memory: _extractPath(jsonResponse, preset.memoryPath),
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        error: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  String _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
    if (data is! Map) return data.toString();

    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}
