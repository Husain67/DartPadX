// ignore_for_file: prefer_const_declarations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/compiler_preset.dart';

const String _defaultOneCompilerId = 'preset_onecompiler_default';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final String oneCompilerApiKey;

  SettingsState({
    required this.presets,
    required this.activePresetId,
    required this.oneCompilerApiKey,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    String? oneCompilerApiKey,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      oneCompilerApiKey: oneCompilerApiKey ?? this.oneCompilerApiKey,
    );
  }

  CompilerPreset get activePreset => presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _presetBox;
  late Box _settingsBox;

  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: '', oneCompilerApiKey: '')) {
    _init();
  }

  SettingsState get currentState => state;

  Future<void> _init() async {
    _presetBox = Hive.box<CompilerPreset>('presets');
    _settingsBox = Hive.box('settings');

    if (_presetBox.isEmpty) {
      _loadDefaultPresets();
    }

    final activeId = _settingsBox.get('activePresetId', defaultValue: _defaultOneCompilerId);
    final key = const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: '');
    final storedKey = _settingsBox.get('oneCompilerApiKey', defaultValue: key);

    state = SettingsState(
      presets: _presetBox.values.toList(),
      activePresetId: activeId,
      oneCompilerApiKey: storedKey,
    );
  }

  void _loadDefaultPresets() {
    final List<CompilerPreset> presets = [
      CompilerPreset(
        id: _defaultOneCompilerId,
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'X-RapidAPI-Key': '{api_key}',
        },
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'preset_jdoodle',
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {
          'content-type': 'application/json',
        },
        queryParams: {},
        bodyTemplate: '{\n  "clientId": "{client_id}",\n  "clientSecret": "{client_secret}",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "4"\n}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'preset_piston',
        name: 'Piston',
        url: 'https://emacs.ch/api/v2/execute',
        method: 'POST',
        authType: 'None',
        headers: {
          'content-type': 'application/json',
        },
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'preset_blank',
        name: 'Blank',
        url: 'https://api.example.com/execute',
        method: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isReadOnly: false,
      ),
    ];

    for (var preset in presets) {
      _presetBox.put(preset.id, preset);
    }
  }

  void setActivePreset(String id) {
    _settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void saveApiKey(String key) {
    _settingsBox.put('oneCompilerApiKey', key);
    state = state.copyWith(oneCompilerApiKey: key);
  }

  void addOrUpdatePreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetBox.values.toList());
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    if (state.activePresetId == id) {
      setActivePreset(_defaultOneCompilerId);
    } else {
      state = state.copyWith(presets: _presetBox.values.toList());
    }
  }
}
