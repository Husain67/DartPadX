import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import 'settings_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    required this.isRunning,
    required this.stdout,
    required this.stderr,
    required this.error,
    required this.executionTime,
    required this.memory,
  });

  factory ExecutionState.initial() => ExecutionState(
        isRunning: false,
        stdout: '',
        stderr: '',
        error: '',
        executionTime: '',
        memory: '',
      );

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

  ExecutionNotifier(this.ref) : super(ExecutionState.initial());

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    final settings = ref.read(settingsProvider);
    CompilerPreset? preset;

    if (settings.useDefaultOneCompiler) {
      preset = AppConstants.predefinedPresets.firstWhere((p) => p.id == 'pre_onecompiler');
    } else {
      preset = ref.read(settingsProvider.notifier).activePreset;
    }

    if (preset == null) {
      state = state.copyWith(isRunning: false, error: 'No compiler preset selected.');
      return;
    }

    try {
      final startTime = DateTime.now();

      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      final headers = Map<String, String>.from(preset.headers);

      switch (preset.authType) {
        case 'API-Key Header':
          if (preset.authKey.isNotEmpty && preset.authValue.isNotEmpty) {
            headers[preset.authKey] = preset.authValue;
          }
          break;
        case 'Bearer Token':
          if (preset.authValue.isNotEmpty) {
            headers['Authorization'] = 'Bearer ${preset.authValue}';
          }
          break;
        case 'Basic Auth':
          if (preset.authKey.isNotEmpty && preset.authValue.isNotEmpty) {
            headers['Authorization'] = 'Basic ${Utils.encodeBasicAuth(preset.authKey, preset.authValue)}';
          }
          break;
      }

      String body = preset.requestBodyTemplate;

      // Safety replacement logic to avoid broken JSON
      String encodedCode = jsonEncode(code);
      String encodedStdin = jsonEncode(stdin);

      body = body.replaceAll('"{code}"', encodedCode);
      body = body.replaceAll('"{stdin}"', encodedStdin);

      // Fallback if template doesn't use quotes around placeholders
      body = body.replaceAll('{code}', encodedCode.substring(1, encodedCode.length - 1));
      body = body.replaceAll('{stdin}', encodedStdin.substring(1, encodedStdin.length - 1));

      http.Response response;

      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      final executionDuration = DateTime.now().difference(startTime);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        final stdoutVal = Utils.extractJsonPath(jsonResponse, preset.stdoutPath)?.toString() ?? '';
        final stderrVal = Utils.extractJsonPath(jsonResponse, preset.stderrPath)?.toString() ?? '';
        final errorVal = Utils.extractJsonPath(jsonResponse, preset.errorPath)?.toString() ?? '';

        String timeVal = Utils.extractJsonPath(jsonResponse, preset.executionTimePath)?.toString() ?? '';
        if (timeVal.isEmpty) {
          timeVal = '${executionDuration.inMilliseconds} ms';
        } else if (!timeVal.contains('ms') && !timeVal.contains('s')) {
          timeVal = '$timeVal ms';
        }

        final memoryVal = Utils.extractJsonPath(jsonResponse, preset.memoryPath)?.toString() ?? '';

        state = state.copyWith(
          isRunning: false,
          stdout: stdoutVal,
          stderr: stderrVal,
          error: errorVal,
          executionTime: timeVal,
          memory: memoryVal,
        );
      } else {
        state = state.copyWith(
          isRunning: false,
          error: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: 'Execution failed: $e',
      );
    }
  }

  void clearOutput() {
    state = ExecutionState.initial();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) => ExecutionNotifier(ref));
