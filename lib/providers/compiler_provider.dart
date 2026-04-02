import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  // Execution state
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  late Box<CompilerPreset> _presetsBox;
  late Box _settingsBox;
  final _uuid = const Uuid();

  void _loadPresets() {
    _presetsBox = Hive.box<CompilerPreset>(AppConstants.hiveBoxPresets);
    _settingsBox = Hive.box(AppConstants.hiveBoxSettings);

    List<CompilerPreset> loadedPresets = _presetsBox.values.toList();

    // Seed default presets if empty
    if (loadedPresets.isEmpty) {
      loadedPresets = _getDefaultPresets();
      for (var p in loadedPresets) {
        _presetsBox.put(p.id, p);
      }
    }

    final activeId = _settingsBox.get('activePresetId', defaultValue: loadedPresets.first.id);
    final useDefault = _settingsBox.get('useDefaultOneCompiler', defaultValue: true);

    state = state.copyWith(
      presets: loadedPresets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void setUseDefault(bool useDefault) {
    _settingsBox.put('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void setActivePreset(String id) {
    _settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final updatedList = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedList);
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    String? nextId = state.activePresetId == id ? (remaining.isNotEmpty ? remaining.first.id : null) : state.activePresetId;
    if (nextId != state.activePresetId && nextId != null) {
       _settingsBox.put('activePresetId', nextId);
    }
    state = state.copyWith(presets: remaining, activePresetId: nextId);
  }

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      if (state.useDefaultOneCompiler) {
        await _runDefaultOneCompiler(code, stdin);
      } else {
        await _runCustomPreset(code, stdin);
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Execution Error:\n$e',
      );
    }
  }

  Future<void> _runDefaultOneCompiler(String code, String stdin) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': AppConstants.defaultOneCompilerKey,
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        'language': 'dart',
        'stdin': stdin,
        'files': [
          {'name': 'main.dart', 'content': code}
        ]
      }),
    );

    _parseOneCompilerResponse(response.body);
  }

  void _parseOneCompilerResponse(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      final stdout = json['stdout'] ?? '';
      final stderr = json['stderr'] ?? json['exception'] ?? '';
      final time = json['executionTime']?.toString() ?? '';

      state = state.copyWith(
        isExecuting: false,
        stdout: stdout,
        stderr: stderr,
        executionTime: time.isNotEmpty ? '${time}ms' : '',
      );
    } catch (e) {
      state = state.copyWith(isExecuting: false, stderr: 'Failed to parse response: $e\nRaw: $responseBody');
    }
  }

  Future<void> _runCustomPreset(String code, String stdin) async {
    final preset = state.presets.firstWhere((p) => p.id == state.activePresetId);

    // Prepare Headers
    Map<String, String> headers = Map.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
      headers[preset.authKey] = preset.authValue;
    } else if (preset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth') {
      final encoded = base64Encode(utf8.encode(preset.authValue));
      headers['Authorization'] = 'Basic $encoded';
    }

    // Prepare Query Params
    Map<String, String> qParams = Map.from(preset.queryParams);
    if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
      qParams[preset.authKey] = preset.authValue;
    }

    // Build URL
    Uri url = Uri.parse(preset.endpoint);
    if (qParams.isNotEmpty) {
      url = url.replace(queryParameters: qParams);
    }

    // Prepare Body
    String body = preset.bodyTemplate;
    // Safely encode code and stdin to JSON strings, then remove surrounding quotes
    // so they fit into the template as valid JSON strings if needed.
    String encodedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    String encodedStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

    body = body.replaceAll('{code}', encodedCode);
    body = body.replaceAll('{stdin}', encodedStdin);
    body = body.replaceAll('{language}', 'dart');

    http.Response response;
    final stopwatch = Stopwatch()..start();

    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (preset.method.toUpperCase() == 'PUT') {
      response = await http.put(url, headers: headers, body: body);
    } else {
      response = await http.post(url, headers: headers, body: body);
    }

    stopwatch.stop();

    _parseCustomResponse(response.body, preset, stopwatch.elapsedMilliseconds);
  }

  void _parseCustomResponse(String bodyStr, CompilerPreset preset, int localTimeMs) {
    try {
      final json = jsonDecode(bodyStr);

      String extractPath(String path) {
        if (path.isEmpty) return '';
        final parts = path.split('.');
        dynamic current = json;
        for (var part in parts) {
          if (current is Map && current.containsKey(part)) {
            current = current[part];
          } else {
            return '';
          }
        }
        return current?.toString() ?? '';
      }

      final out = extractPath(preset.stdoutPath);
      String err = extractPath(preset.stderrPath);
      final errorField = extractPath(preset.errorPath);
      if (err.isEmpty && errorField.isNotEmpty) err = errorField;

      String time = extractPath(preset.executionTimePath);
      if (time.isEmpty) time = '${localTimeMs}ms';

      final mem = extractPath(preset.memoryPath);

      state = state.copyWith(
        isExecuting: false,
        stdout: out,
        stderr: err,
        executionTime: time,
        memory: mem,
      );

    } catch (e) {
      // If not JSON, dump raw
      state = state.copyWith(
        isExecuting: false,
        stdout: bodyStr,
        stderr: 'Response parsing error (Not JSON?): $e',
        executionTime: '${localTimeMs}ms',
      );
    }
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler (Custom)',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: AppConstants.defaultOneCompilerKey,
        headers: {'Content-Type': 'application/json', 'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston (v2)',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit API',
        endpoint: 'https://api.replit.com/v1/exec',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX API',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        stdoutPath: 'output',
        errorPath: 'error',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth API',
        endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_SECRET'},
        bodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank Preset',
        endpoint: 'https://...',
      )
    ];
  }

  void importPresetsFromJson(String jsonStr) {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        final p = CompilerPreset.fromJson(item as Map<String, dynamic>);
        p.id = _uuid.v4(); // Generate new IDs for imported to avoid conflicts
        _presetsBox.put(p.id, p);
      }
      state = state.copyWith(presets: _presetsBox.values.toList());
    } catch (e) {
      throw Exception('Invalid JSON format');
    }
  }

  String exportPresetsToJson() {
    final list = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(list);
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '');
  }
}
