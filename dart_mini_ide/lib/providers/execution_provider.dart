import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'settings_provider.dart';
import 'compiler_preset_provider.dart';
import 'file_provider.dart';

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
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;
  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clear() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final activeFile = ref.read(fileProvider).files.firstWhere((f) => f.id == ref.read(fileProvider).activeFileId, orElse: () => throw Exception('No active file'));
    final useDefault = ref.read(useDefaultOneCompilerProvider);

    state = ExecutionState(isRunning: true);

    try {
      if (useDefault) {
        await _executeDefault(activeFile.content);
      } else {
        await _executeCustom(activeFile.content);
      }
    } catch (e) {
      state = ExecutionState(stderr: 'Execution Error: $e');
    }
  }

  Future<void> _executeDefault(String code) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final headers = {
      'Content-Type': 'application/json',
      'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    };
    final body = jsonEncode({
      'language': 'dart',
      'stdin': '',
      'files': [
        {'name': 'main.dart', 'content': code}
      ]
    });

    final stopwatch = Stopwatch()..start();
    final res = await http.post(url, headers: headers, body: body);
    stopwatch.stop();

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      state = ExecutionState(
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? data['exception'] ?? '',
        executionTime: '${stopwatch.elapsedMilliseconds} ms',
        memory: '',
      );
    } else {
      state = ExecutionState(stderr: 'HTTP Error ${res.statusCode}: ${res.body}');
    }
  }

  Future<void> _executeCustom(String code) async {
    final presetId = ref.read(activePresetIdProvider);
    if (presetId == null) throw Exception('No custom preset selected');
    final preset = ref.read(compilerPresetProvider).firstWhere((p) => p.id == presetId);

    var uri = Uri.parse(preset.url);
    if (preset.queryParams.isNotEmpty) {
      final qp = Map<String, String>.fromEntries(preset.queryParams);
      uri = uri.replace(queryParameters: qp);
    }

    final headers = <String, String>{};
    for (final h in preset.headers) {
      headers[h.key] = h.value;
    }

    if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      headers['Authorization'] = 'Basic $encoded';
    } else if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
      if (!headers.containsKey('x-api-key') && !headers.containsKey('X-API-Key') && !headers.containsKey('Authorization')) {
        headers['x-api-key'] = preset.authValue;
      }
    }

    String bodyStr = preset.bodyTemplate;
    bodyStr = bodyStr.replaceAll('{language}', 'dart');
    bodyStr = bodyStr.replaceAll('{stdin}', '');
    final safeCode = jsonEncode(code);
    bodyStr = bodyStr.replaceAll('"{code}"', safeCode).replaceAll('{code}', safeCode);

    final stopwatch = Stopwatch()..start();
    http.Response res;
    if (preset.method.toUpperCase() == 'GET') {
      res = await http.get(uri, headers: headers);
    } else {
      res = await http.post(uri, headers: headers, body: bodyStr);
    }
    stopwatch.stop();

    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        final data = jsonDecode(res.body);
        String getValue(String path) {
          if (path.isEmpty) return '';
          final parts = path.split('.');
          dynamic current = data;
          for (final p in parts) {
            if (current is Map && current.containsKey(p)) {
              current = current[p];
            } else {
              return '';
            }
          }
          return current?.toString() ?? '';
        }

        state = ExecutionState(
          stdout: getValue(preset.responseMappings['stdout'] ?? ''),
          stderr: getValue(preset.responseMappings['stderr'] ?? '') + getValue(preset.responseMappings['error'] ?? ''),
          executionTime: getValue(preset.responseMappings['executionTime'] ?? '').isNotEmpty
              ? getValue(preset.responseMappings['executionTime'] ?? '')
              : '${stopwatch.elapsedMilliseconds} ms',
          memory: getValue(preset.responseMappings['memory'] ?? ''),
        );
      } catch (e) {
        state = ExecutionState(stdout: res.body, stderr: 'Failed to parse JSON response');
      }
    } else {
      state = ExecutionState(stderr: 'HTTP Error ${res.statusCode}: ${res.body}');
    }
  }
}
