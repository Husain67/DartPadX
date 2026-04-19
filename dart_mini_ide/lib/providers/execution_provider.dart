import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dart_style/dart_style.dart';
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String? stdout;
  final String? stderr;
  final String? executionTime;
  final String? memory;
  final String? error;

  ExecutionState({
    this.isRunning = false,
    this.stdout,
    this.stderr,
    this.executionTime,
    this.memory,
    this.error,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? error,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      error: error ?? this.error,
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
    state = state.copyWith(isRunning: true, stdout: null, stderr: null, error: null, executionTime: null, memory: null);

    final settings = ref.read(settingsProvider);
    final activePreset = settings.useDefaultOneCompiler
      ? settings.presets.firstWhere((p) => p.id == 'oc_default')
      : settings.presets.firstWhere((p) => p.id == settings.activePresetId, orElse: () => settings.presets.firstWhere((p) => p.id == 'oc_default'));

    try {
      final headers = <String, String>{};
      for (var header in activePreset.headers) {
        if (header.key.isNotEmpty) headers[header.key] = header.value;
      }

      if (activePreset.authType == 'API-Key Header') {
        headers['X-RapidAPI-Key'] = activePreset.authValue; // Specific for OneCompiler, but can be genericized
      } else if (activePreset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${activePreset.authValue}';
      } else if (activePreset.authType == 'Basic Auth') {
        final bytes = utf8.encode(activePreset.authValue);
        final base64Str = base64.encode(bytes);
        headers['Authorization'] = 'Basic $base64Str';
      }

      final uri = Uri.parse(activePreset.endpointUrl).replace(
        queryParameters: activePreset.queryParams.isEmpty ? null : {
          for (var q in activePreset.queryParams) if(q.key.isNotEmpty) q.key: q.value
        }
      );

      final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
      String body = activePreset.bodyTemplate.replaceAll('{code}', '"$safeCode"');
      // basic stdin support stub
      body = body.replaceAll('{stdin}', '""');

      late http.Response response;

      if (activePreset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (activePreset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        throw Exception("Unsupported HTTP Method");
      }

      final decoded = jsonDecode(response.body);

      String? extract(String path) {
        if (path.isEmpty) return null;
        final parts = path.split('.');
        dynamic current = decoded;
        for (var part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return null;
          }
        }
        return current?.toString();
      }

      state = state.copyWith(
        isRunning: false,
        stdout: extract(activePreset.stdoutPath),
        stderr: extract(activePreset.stderrPath),
        error: extract(activePreset.errorPath),
        executionTime: extract(activePreset.executionTimePath),
        memory: extract(activePreset.memoryPath),
      );

    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  String formatCode(String code) {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      return formatter.format(code);
    } catch (e) {
      // formatting failed (likely syntax error)
      return code;
    }
  }
}
