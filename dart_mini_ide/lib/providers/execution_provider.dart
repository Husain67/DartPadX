import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../utils/constants.dart';
import 'settings_provider.dart';

final compilerPresetBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  return Hive.box<CompilerPreset>('compiler_presets');
});

final defaultPresetProvider = StateProvider<String?>((ref) {
  return null; // ID of the default preset if useDefaultOneCompiler is false
});

class ExecutionResult {
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;
  final bool isExecuting;

  ExecutionResult({
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.time = '',
    this.memory = '',
    this.isExecuting = false,
  });
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionResult>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionNotifier extends StateNotifier<ExecutionResult> {
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionResult());

  void clear() {
    state = ExecutionResult();
  }

  Future<void> executeCode(String code) async {
    state = ExecutionResult(isExecuting: true);
    final useDefault = _ref.read(useDefaultOneCompilerProvider);

    if (useDefault) {
      await _executeOneCompiler(code);
    } else {
      final defaultId = _ref.read(defaultPresetProvider);
      if (defaultId == null) {
        state = ExecutionResult(error: 'No default custom preset selected.');
        return;
      }
      final box = _ref.read(compilerPresetBoxProvider);
      final preset = box.get(defaultId);
      if (preset == null) {
        state = ExecutionResult(error: 'Custom preset not found.');
        return;
      }
      await _executeCustomPreset(code, preset);
    }
  }

  Future<void> _executeOneCompiler(String code) async {
    try {
      final response = await http.post(
        Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run'),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': Constants.defaultOneCompilerKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        body: jsonEncode({
          'language': 'dart',
          'stdin': '',
          'files': [
            {'name': 'main.dart', 'content': code}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = ExecutionResult(
          stdout: data['stdout']?.toString() ?? '',
          stderr: data['stderr']?.toString() ?? '',
          error: data['exception']?.toString() ?? '',
          time: data['executionTime']?.toString() ?? '',
          memory: '',
        );
      } else {
        state = ExecutionResult(error: 'Failed to execute: ${response.statusCode}\\n${response.body}');
      }
    } catch (e) {
      state = ExecutionResult(error: 'Error: $e');
    }
  }

  Future<void> _executeCustomPreset(String code, CompilerPreset preset) async {
    try {
      // Prepare Request Body
      String body = preset.requestBodyTemplate;
      body = body.replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''));
      body = body.replaceAll('{language}', 'dart');
      body = body.replaceAll('{stdin}', '');

      // Prepare Headers
      Map<String, String> headers = Map.from(preset.headers);
      if (preset.authType == 'API-Key Header') {
        final parts = preset.authValue.split(':');
        if (parts.length == 2) {
          headers[parts[0]] = parts[1];
        }
      } else if (preset.authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${preset.authValue}';
      } else if (preset.authType == 'Basic Auth') {
        headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(preset.authValue))}';
      }

      // Prepare Query Params
      Map<String, String> queryParams = Map.from(preset.queryParams);
      if (preset.authType == 'Query Param') {
        final parts = preset.authValue.split('=');
        if (parts.length == 2) {
          queryParams[parts[0]] = parts[1];
        }
      }

      Uri uri = Uri.parse(preset.endpointUrl);
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      http.Response response;
      if (preset.httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else if (preset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        state = ExecutionResult(
          stdout: _extractPath(data, preset.stdoutPath),
          stderr: _extractPath(data, preset.stderrPath),
          error: _extractPath(data, preset.errorPath),
          time: _extractPath(data, preset.executionTimePath),
          memory: _extractPath(data, preset.memoryPath),
        );
      } else {
        state = ExecutionResult(error: 'Execution Failed (${response.statusCode}):\\n${response.body}');
      }
    } catch (e) {
      state = ExecutionResult(error: 'Exception: $e');
    }
  }

  String _extractPath(dynamic data, String path) {
    if (path.isEmpty || data == null) return '';
    try {
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
    } catch (e) {
      return '';
    }
  }
}
