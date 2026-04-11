import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({
    this.useDefaultOneCompiler = true,
    this.presets = const [],
    this.activePresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SharedPreferences? _prefs;
  Box<CompilerPreset>? _box;

  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _box = Hive.box<CompilerPreset>('compiler_presets');

    final useDefault = _prefs?.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs?.getString('activePresetId');

    var savedPresets = _box!.values.toList();

    if (savedPresets.isEmpty) {
      // Pre-load default custom presets
      savedPresets = _getPreloadedPresets();
      for (var p in savedPresets) {
        await _box!.put(p.id, p);
      }
    }

    state = SettingsState(
      useDefaultOneCompiler: useDefault,
      presets: savedPresets,
      activePresetId: activeId ?? (savedPresets.isNotEmpty ? savedPresets.first.id : null),
    );
  }

  void setUseDefaultOneCompiler(bool useDefault) {
    _prefs?.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void setActivePreset(String id) {
    _prefs?.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box?.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box?.put(preset.id, preset);
    final updatedList = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedList);
  }

  void deletePreset(String id) {
    _box?.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: remaining);
    if (state.activePresetId == id) {
      final newActive = remaining.isNotEmpty ? remaining.first.id : null;
      if (newActive != null) _prefs?.setString('activePresetId', newActive);
      state = state.copyWith(activePresetId: newActive);
    }
  }

  void duplicatePreset(CompilerPreset preset) {
     final newPreset = preset.copyWithNewId();
     addPreset(newPreset);
  }

  Future<String> exportPresets() async {
     final list = state.presets.map((p) => {
        'id': p.id,
        'name': p.name,
        'endpointUrl': p.endpointUrl,
        'httpMethod': p.httpMethod,
        'authType': p.authType,
        'authValue': p.authValue,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'requestBodyTemplate': p.requestBodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
     }).toList();
     return jsonEncode(list);
  }

  void importPresets(String jsonString) {
      try {
          final List<dynamic> list = jsonDecode(jsonString);
          for (var item in list) {
              final preset = CompilerPreset(
                  id: item['id'] ?? const Uuid().v4(),
                  name: item['name'] ?? 'Imported Preset',
                  endpointUrl: item['endpointUrl'] ?? '',
                  httpMethod: item['httpMethod'] ?? 'POST',
                  authType: item['authType'] ?? 'None',
                  authValue: item['authValue'] ?? '',
                  headers: Map<String, String>.from(item['headers'] ?? {}),
                  queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
                  requestBodyTemplate: item['requestBodyTemplate'] ?? '',
                  stdoutPath: item['stdoutPath'] ?? '',
                  stderrPath: item['stderrPath'] ?? '',
                  errorPath: item['errorPath'] ?? '',
                  executionTimePath: item['executionTimePath'] ?? '',
                  memoryPath: item['memoryPath'] ?? '',
              );
              addPreset(preset);
          }
      } catch (e) {
          // Ignore parse errors on import
      }
  }

  List<CompilerPreset> _getPreloadedPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'YOUR_RAPIDAPI_KEY',
        headers: {'Content-Type': 'application/json', 'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com', 'X-RapidAPI-Key': 'YOUR_RAPIDAPI_KEY'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "language": "dart",\\n  "stdin": "{stdin}",\\n  "files": [\\n    {\\n      "name": "main.dart",\\n      "content": "{code}"\\n    }\\n  ]\\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "clientId": "YOUR_CLIENT_ID",\\n  "clientSecret": "YOUR_CLIENT_SECRET",\\n  "script": "{code}",\\n  "language": "dart",\\n  "versionIndex": "0"\\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "language": "dart",\\n  "version": "*",\\n  "files": [\\n    {\\n      "content": "{code}"\\n    }\\n  ]\\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/execute',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "language": "dart",\\n  "code": "{code}"\\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "lang": "DART",\\n  "source": "{code}"\\n}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpointUrl: 'https://example.com/api/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\\n  "code": "{code}",\\n  "language": "{language}"\\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      ),
    ];
  }
}
