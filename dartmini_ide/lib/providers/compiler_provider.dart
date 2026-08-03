import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/preset_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompilerState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;
  final List<PresetModel> presets;
  final String? activePresetId;
  final bool useOneCompiler;

  CompilerState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.time = '',
    this.memory = '',
    required this.presets,
    this.activePresetId,
    this.useOneCompiler = true,
  });

  CompilerState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? time,
    String? memory,
    List<PresetModel>? presets,
    String? activePresetId,
    bool? useOneCompiler,
  }) {
    return CompilerState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<PresetModel> _box;
  final SharedPreferences _prefs;

  CompilerNotifier(this._box, this._prefs)
      : super(CompilerState(
          presets: _box.values.toList(),
          useOneCompiler: _prefs.getBool('useOneCompiler') ?? true,
          activePresetId: _prefs.getString('activePresetId'),
        )) {
    if (state.presets.isEmpty) {
      _loadInitialPresets();
    }
  }

  void _loadInitialPresets() {
    final List<PresetModel> initials = [
      PresetModel(
        id: 'onecompiler',
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: 'memory',
      ),
      PresetModel(
        id: 'jdoodle',
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      PresetModel(
        id: 'piston',
        name: 'Piston (Enginev)',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      PresetModel(
        id: 'replit',
        name: 'Replit',
        endpoint: 'https://replit.com/api/v1/repls/...',
        method: 'POST',
        authType: 'Bearer Token',
        bodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      ),
      PresetModel(
        id: 'codex',
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        bodyTemplate: '{"code": "{code}", "language": "dart"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      PresetModel(
        id: 'hackerearth',
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v3/code/run/',
        method: 'POST',
        authType: 'None',
        bodyTemplate: '{"client_secret": "YOUR_SECRET", "source": "{code}", "lang": "DART"}',
        stdoutPath: 'run_status.output',
        stderrPath: 'run_status.stderr',
        errorPath: 'compile_status',
        executionTimePath: 'run_status.time_used',
        memoryPath: 'run_status.memory_used',
      ),
      PresetModel(
        id: 'blank',
        name: 'Blank',
        endpoint: '',
        method: 'POST',
        authType: 'None',
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];
    for (var p in initials) {
      _box.put(p.id, p);
    }
    state = state.copyWith(presets: _box.values.toList());
  }

  void savePreset(PresetModel preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.copyWith(
      presets: _box.values.toList(),
      activePresetId: state.activePresetId == id ? null : state.activePresetId,
    );
    if (state.activePresetId == id) {
      _prefs.remove('activePresetId');
    }
  }

  void setUseOneCompiler(bool value) {
    _prefs.setBool('useOneCompiler', value);
    state = state.copyWith(useOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', error: '', time: '', memory: '');
  }

  void importPresets(List<PresetModel> newPresets) {
    for(var p in newPresets) {
      _box.put(p.id, p);
    }
    state = state.copyWith(presets: _box.values.toList());
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', time: '', memory: '');
    try {
      if (state.useOneCompiler) {
        await _executeOneCompiler(code, stdin);
      } else {
        await _executeCustomPreset(code, stdin);
      }
    } catch (e) {
      state = state.copyWith(error: 'Execution Error: \$e', isExecuting: false);
    }
  }

  Future<void> _executeOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [
          {"name": "main.dart", "content": code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      state = state.copyWith(
        isExecuting: false,
        stdout: res['stdout'] ?? '',
        stderr: res['stderr'] ?? '',
        error: res['exception'] ?? '',
        time: res['executionTime']?.toString() ?? '',
        memory: res['memory']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(isExecuting: false, error: 'OneCompiler Error: \${response.statusCode}\\n\${response.body}');
    }
  }

  Future<void> _executeCustomPreset(String code, String stdin) async {
    final preset = state.presets.firstWhere(
      (p) => p.id == state.activePresetId,
      orElse: () => throw Exception('No active preset selected'),
    );

    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
        .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
        .replaceAll('{language}', 'dart');

    final uriStr = preset.endpoint;
    Uri uri = Uri.parse(uriStr);

    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer \${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      headers['Authorization'] = 'Basic \${base64Encode(utf8.encode(preset.authValue))}';
    } else if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
       var params = Map<String, dynamic>.from(uri.queryParameters);
       params[preset.authKey] = preset.authValue;
       uri = uri.replace(queryParameters: params);
    }

    if (!headers.containsKey('Content-Type') && preset.method.toUpperCase() != 'GET') {
      headers['Content-Type'] = 'application/json';
    }

    http.Response response;
    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(uri, headers: headers);
    } else {
      response = await http.post(uri, headers: headers, body: bodyStr);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final res = jsonDecode(response.body);

      dynamic getValue(dynamic map, String path) {
        if (path.isEmpty || map == null) return null;
        final keys = path.split('.');
        dynamic current = map;
        for (var k in keys) {
          if (current is Map && current.containsKey(k)) {
            current = current[k];
          } else {
            return null;
          }
        }
        return current;
      }

      state = state.copyWith(
        isExecuting: false,
        stdout: getValue(res, preset.stdoutPath)?.toString() ?? '',
        stderr: getValue(res, preset.stderrPath)?.toString() ?? '',
        error: getValue(res, preset.errorPath)?.toString() ?? '',
        time: getValue(res, preset.executionTimePath)?.toString() ?? '',
        memory: getValue(res, preset.memoryPath)?.toString() ?? '',
      );
    } else {
      state = state.copyWith(isExecuting: false, error: 'Custom API Error: \${response.statusCode}\\n\${response.body}');
    }
  }

  // A helper method that can test the connection in a dialog without updating global output state
  Future<Map<String, dynamic>> testConnection(PresetModel preset) async {
    String code = "void main() { print('Hello from custom API'); }";
    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
        .replaceAll('{stdin}', '')
        .replaceAll('{language}', 'dart');

    Uri uri = Uri.parse(preset.endpoint);

    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: preset.queryParams);
    }

    final headers = Map<String, String>.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer \${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      headers['Authorization'] = 'Basic \${base64Encode(utf8.encode(preset.authValue))}';
    } else if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
       var params = Map<String, dynamic>.from(uri.queryParameters);
       params[preset.authKey] = preset.authValue;
       uri = uri.replace(queryParameters: params);
    }

    if (!headers.containsKey('Content-Type') && preset.method.toUpperCase() != 'GET') {
      headers['Content-Type'] = 'application/json';
    }

    http.Response response;
    final stopwatch = Stopwatch()..start();
    try {
      if (preset.method.toUpperCase() == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }
      stopwatch.stop();

      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (e) {
        // Not JSON
      }

      dynamic getValue(dynamic map, String path) {
        if (path.isEmpty || map == null) return null;
        final keys = path.split('.');
        dynamic current = map;
        for (var k in keys) {
          if (current is Map && current.containsKey(k)) {
            current = current[k];
          } else {
            return null;
          }
        }
        return current;
      }

      return {
        'success': true,
        'statusCode': response.statusCode,
        'rawBody': response.body,
        'time': '\${stopwatch.elapsedMilliseconds} ms',
        'stdout': getValue(parsed, preset.stdoutPath)?.toString() ?? '',
        'stderr': getValue(parsed, preset.stderrPath)?.toString() ?? '',
        'error': getValue(parsed, preset.errorPath)?.toString() ?? '',
        'parsedTime': getValue(parsed, preset.executionTimePath)?.toString() ?? '',
        'parsedMemory': getValue(parsed, preset.memoryPath)?.toString() ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<PresetModel>('presets');
  final prefs = ref.watch(sharedPrefsProvider);
  return CompilerNotifier(box, prefs);
});
