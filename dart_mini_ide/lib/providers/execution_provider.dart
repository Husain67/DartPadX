import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  void clear() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code) async {
    final settings = ref.read(settingsProvider);
    CompilerPreset preset;

    if (settings.useDefaultOneCompiler) {
      preset = settings.presets.firstWhere((p) => p.name.contains('OneCompiler API (Default)'));
    } else {
      final id = settings.activePresetId;
      if (id == null) {
        state = state.copyWith(stderr: 'No custom preset selected.');
        return;
      }
      preset = settings.presets.firstWhere((p) => p.id == id, orElse: () => settings.presets.first);
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      Uri uri = Uri.parse(preset.endpointUrl);
      if (preset.queryParams.isNotEmpty) {
        final queryParams = Map<String, dynamic>.from(uri.queryParameters);
        queryParams.addAll(preset.queryParams);
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = Map<String, String>.from(preset.headers);
      if (preset.authType == 'Bearer Token' && headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer ${headers['Authorization']}';
      } else if (preset.authType == 'Basic Auth' && headers.containsKey('Authorization')) {
        final authVal = headers['Authorization']!;
        final bytes = utf8.encode(authVal);
        headers['Authorization'] = 'Basic ${base64.encode(bytes)}';
      }

      String bodyStr = preset.bodyTemplate;
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''));

      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final outStr = _extractByPath(data, preset.stdoutPath);
        final errStr = _extractByPath(data, preset.stderrPath);
        final errorStr = _extractByPath(data, preset.errorPath);
        final timeStr = _extractByPath(data, preset.executionTimePath);
        final memStr = _extractByPath(data, preset.memoryPath);

        final combinedErr = [errStr, errorStr].where((s) => s.isNotEmpty).join('\n');

        state = state.copyWith(
          isExecuting: false,
          stdout: outStr,
          stderr: combinedErr,
          executionTime: timeStr.isNotEmpty ? '${timeStr}ms' : '',
          memory: memStr,
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'HTTP Error: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Execution Error:\n$e',
      );
    }
  }

  String _extractByPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
    final parts = path.split('.');
    dynamic current = data;
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
