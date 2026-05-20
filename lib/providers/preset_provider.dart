import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresetState {
  final List<PresetModel> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  PresetState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
  });

  PresetState copyWith({
    List<PresetModel>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler:
          useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  final Box<PresetModel> _box = Hive.box<PresetModel>('presets');
  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;

  PresetNotifier() : super(PresetState(presets: [])) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    List<PresetModel> savedPresets = _box.values.toList();

    if (savedPresets.isEmpty) {
      savedPresets = _getPreloadedPresets();
      for (var p in savedPresets) {
        _box.put(p.id, p);
      }
    }

    final useDefault = _prefs?.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs?.getString('activePresetId') ?? (savedPresets.isNotEmpty ? savedPresets.first.id : null);

    state = PresetState(
      presets: savedPresets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void addPreset(PresetModel preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(PresetModel preset) {
    _box.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();

    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = remaining.isNotEmpty ? remaining.first.id : null;
      _prefs?.setString('activePresetId', newActiveId ?? '');
    }

    state = state.copyWith(presets: remaining, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    _prefs?.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void setUseDefaultOneCompiler(bool value) {
    _prefs?.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  PresetModel? get activePreset {
      if (state.activePresetId == null) return null;
      try {
        return state.presets.firstWhere((p) => p.id == state.activePresetId);
      } catch (_) {
          return null;
      }
  }

  List<PresetModel> _getPreloadedPresets() {
    return [
      PresetModel(
        id: _uuid.v4(),
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: '',
        headers: {
            'content-type': 'application/json',
            'X-RapidAPI-Key': 'placeholder_key',
            'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'exception',
        responseTimePath: 'executionTime',
        responseMemoryPath: '',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{\n  "clientId": "your_client_id",\n  "clientSecret": "your_client_secret",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        responseStdoutPath: 'output',
        responseStderrPath: '',
        responseErrorPath: 'error',
        responseTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'Piston',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        responseErrorPath: 'message',
        responseTimePath: '',
        responseMemoryPath: '',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'Replit',
        endpoint: 'https://replit.com/api/v1/run',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'error',
        responseTimePath: '',
        responseMemoryPath: '',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: '',
        responseTimePath: '',
        responseMemoryPath: '',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v3/code/run/',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        responseStdoutPath: 'run_status.output',
        responseStderrPath: 'run_status.stderr',
        responseErrorPath: 'compile_status',
        responseTimePath: 'run_status.time_used',
        responseMemoryPath: 'run_status.memory_used',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'Blank',
        endpoint: '',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        responseStdoutPath: '',
        responseStderrPath: '',
        responseErrorPath: '',
        responseTimePath: '',
        responseMemoryPath: '',
      ),
    ];
  }
}

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});
