import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String rawResponse;

  ExecutionState({
    required this.isExecuting,
    required this.stdout,
    required this.stderr,
    required this.executionTime,
    required this.memory,
    required this.rawResponse,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? rawResponse,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }

  factory ExecutionState.initial() => ExecutionState(
        isExecuting: false,
        stdout: '',
        stderr: '',
        executionTime: '',
        memory: '',
        rawResponse: '',
      );
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState.initial());

  void clearOutput() {
    state = ExecutionState.initial();
  }

  Future<void> executeCode({
    required String code,
    required String stdin,
    required CompilerPreset preset,
    bool isTestConnection = false,
  }) async {
    state = state.copyWith(
      isExecuting: true,
      stdout: isTestConnection ? '' : 'Executing...',
      stderr: '',
      executionTime: '',
      memory: '',
      rawResponse: '',
    );

    try {
      final codeToRun = isTestConnection ? "print('Hello from custom API');" : code;

      // Prepare endpoint and query params
      final uri = Uri.parse(preset.endpoint);
      final queryParams = Map<String, String>.from(preset.queryParams);

      // Prepare headers
      final headers = Map<String, String>.from(preset.headers);

      if (preset.authType == 'API-Key Header' && preset.authKey != null && preset.authValue != null) {
        String val = preset.authValue!;
        if (val == "const String.fromEnvironment('RAPID_API_KEY')") {
          val = const String.fromEnvironment('RAPID_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');
        }
        headers[preset.authKey!] = val;
      } else if (preset.authType == 'Bearer Token' && preset.authValue != null) {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth' && preset.authValue != null) {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue!))}';
      } else if (preset.authType == 'Query Param' && preset.authKey != null && preset.authValue != null) {
        queryParams[preset.authKey!] = preset.authValue!;
      }

      final finalUri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      // Prepare body
      String body = preset.bodyTemplate;
      body = body.replaceAll('{language}', 'dart');
      body = body.replaceAll('{stdin}', stdin);

      // Safe JSON escape for code
      final encodedCode = jsonEncode(codeToRun);
      final unquotedCode = encodedCode.substring(1, encodedCode.length - 1); // remove surrounding quotes
      body = body.replaceAll('{code}', '"$unquotedCode"');

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(finalUri, headers: headers, body: body);
      } else if (preset.method.toUpperCase() == 'PUT') {
        response = await http.put(finalUri, headers: headers, body: body);
      } else {
        response = await http.get(finalUri, headers: headers);
      }

      final raw = response.body;
      String out = '';
      String err = '';
      String time = '';
      String mem = '';

      try {
        final jsonResponse = jsonDecode(raw);
        out = _extractPath(jsonResponse, preset.stdoutPath);
        final errOut = _extractPath(jsonResponse, preset.stderrPath);
        final errObj = _extractPath(jsonResponse, preset.errorPath);
        err = [errOut, errObj].where((e) => e.isNotEmpty).join('\n');
        time = _extractPath(jsonResponse, preset.executionTimePath);
        mem = _extractPath(jsonResponse, preset.memoryPath);
      } catch (_) {
        err = 'Failed to parse response or non-JSON response.';
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        err = 'HTTP ${response.statusCode}: $err\n\n$raw';
      }

      state = state.copyWith(
        isExecuting: false,
        stdout: out,
        stderr: err,
        executionTime: time,
        memory: mem,
        rawResponse: raw,
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stdout: '',
        stderr: 'Execution Exception: $e',
      );
    }
  }

  String _extractPath(dynamic json, String path) {
    if (path.isEmpty || json == null) return '';
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
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
  return ExecutionNotifier();
});
