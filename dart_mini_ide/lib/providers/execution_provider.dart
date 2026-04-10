import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

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
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final compilerState = ref.read(compilerProvider);

    // Determine which preset to use
    CompilerPreset? preset;
    if (compilerState.useDefaultOneCompiler) {
      preset = compilerState.presets.firstWhere(
        (p) => p.platformName == 'OneCompiler',
        orElse: () => compilerState.presets.first,
      );
    } else {
      preset = compilerState.selectedPreset;
    }

    if (preset == null) {
      state = state.copyWith(stderr: 'No valid compiler preset selected.');
      return;
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final code = activeFile.content;
      final stdin = ''; // For simplicity, leaving stdin empty or implement it later

      // Prepare URL and Query Params
      var uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      // Prepare Headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
        headers['x-rapidapi-key'] = preset.authValue; // Specific for rapidAPI/OneCompiler as fallback if not in headers
      } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
        final basicAuth = base64Encode(utf8.encode(preset.authValue));
        headers['Authorization'] = 'Basic $basicAuth';
      }

      // Prepare Body
      String body = preset.requestBodyTemplate;

      // Escape code safely for JSON
      String escapedCode = jsonEncode(code);
      escapedCode = escapedCode.substring(1, escapedCode.length - 1); // remove quotes

      String escapedStdin = jsonEncode(stdin);
      escapedStdin = escapedStdin.substring(1, escapedStdin.length - 1);

      body = body.replaceAll('{code}', escapedCode);
      body = body.replaceAll('{stdin}', escapedStdin);
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      if (preset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers, body: body);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final stdoutVal = _getValueByPath(responseData, preset.stdoutPath);
        final stderrVal = _getValueByPath(responseData, preset.stderrPath);
        final errorVal = _getValueByPath(responseData, preset.errorPath);
        final timeVal = _getValueByPath(responseData, preset.executionTimePath);
        final memoryVal = _getValueByPath(responseData, preset.memoryPath);

        state = state.copyWith(
          isExecuting: false,
          stdout: stdoutVal?.toString() ?? '',
          stderr: (stderrVal != null && stderrVal.toString().isNotEmpty)
              ? stderrVal.toString()
              : (errorVal?.toString() ?? ''),
          executionTime: timeVal?.toString() ?? '',
          memory: memoryVal?.toString() ?? '',
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Execution Exception: $e',
      );
    }
  }

  // Parses dot notation like 'run.stdout'
  dynamic _getValueByPath(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
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
