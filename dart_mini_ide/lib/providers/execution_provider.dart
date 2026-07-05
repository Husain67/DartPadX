import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });
}

class ExecutionState {
  final bool isRunning;
  final ExecutionResult? result;

  ExecutionState({
    this.isRunning = false,
    this.result,
  });

  ExecutionState copyWith({
    bool? isRunning,
    ExecutionResult? result,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  Future<void> executeCode(CompilerPreset preset, String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, result: null);

    try {
      // 1. Process URL & Query Params
      var uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: preset.queryParams);
      }

      // 2. Prepare Headers
      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer ${headers["Authorization"]}';
      }

      // 3. Prepare Body
      // We must escape quotes and newlines in code so JSON remains valid
      String safeCode = code;
      String safeStdin = stdin;

      String bodyStr = preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(safeCode).substring(1, jsonEncode(safeCode).length - 1))
          .replaceAll('{stdin}', jsonEncode(safeStdin).substring(1, jsonEncode(safeStdin).length - 1))
          .replaceAll('{language}', 'dart');

      // 4. Make Request
      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers); // Ignoring body for GET
      }

      // 5. Parse Response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        state = state.copyWith(
          isRunning: false,
          result: ExecutionResult(
            stdout: _getValueFromPath(jsonResponse, preset.stdoutPath),
            stderr: _getValueFromPath(jsonResponse, preset.stderrPath),
            error: _getValueFromPath(jsonResponse, preset.errorPath),
            executionTime: _getValueFromPath(jsonResponse, preset.executionTimePath),
            memory: _getValueFromPath(jsonResponse, preset.memoryPath),
          ),
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          result: ExecutionResult(
            error: 'HTTP Error ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        result: ExecutionResult(error: e.toString()),
      );
    }
  }

  String _getValueFromPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return '';
    try {
      final parts = path.split('.');
      dynamic current = json;
      for (final part in parts) {
        if (current == null) return '';
        current = current[part];
      }
      return current?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  void clearOutput() {
    state = state.copyWith(result: null);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
