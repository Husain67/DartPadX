
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useOneCompiler;
  final String activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useOneCompiler,
    required this.activePresetId,
    required this.presets,
  });

  SettingsState copyWith({
    bool? useOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
            useOneCompiler: true, activePresetId: '', presets: [])) {
    _loadSettings();
  }

  Box<CompilerPreset>? _presetsBox;
  SharedPreferences? _prefs;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _presetsBox = Hive.box<CompilerPreset>('compilerPresets');

    bool useOneCompiler = _prefs?.getBool('useOneCompiler') ?? true;
    String activePresetId = _prefs?.getString('activePresetId') ?? '';

    List<CompilerPreset> loadedPresets = _presetsBox!.values.toList();
    if (loadedPresets.isEmpty) {
      _loadDefaultPresets();
      loadedPresets = _presetsBox!.values.toList();
    }

    if (activePresetId.isEmpty && loadedPresets.isNotEmpty) {
      activePresetId = loadedPresets.first.id;
      _prefs?.setString('activePresetId', activePresetId);
    }

    state = SettingsState(
      useOneCompiler: useOneCompiler,
      activePresetId: activePresetId,
      presets: loadedPresets,
    );
  }

  void _loadDefaultPresets() {
    final presets = [
      CompilerPreset(
        platformName: 'OneCompiler API (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': 'YOUR_RAPIDAPI_KEY',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "index.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseMapping: ResponseMapping(
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          executionTimePath: 'executionTime',
        ),
        isEditable: false,
      ),
      CompilerPreset(
        platformName: 'Piston API',
        endpointUrl: 'https://emacs.go.ro/api/v2/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        responseMapping: ResponseMapping(
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          executionTimePath: 'run.compileTime',
        ),
        isEditable: false,
      ),
      CompilerPreset(
        platformName: 'JDoodle API',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        responseMapping: ResponseMapping(
          stdoutPath: 'output',
          memoryPath: 'memory',
          executionTimePath: 'cpuTime',
        ),
        isEditable: false,
      ),
    ];

    for (var preset in presets) {
      _presetsBox?.put(preset.id, preset);
    }
  }

  void setUseOneCompiler(bool value) {
    _prefs?.setBool('useOneCompiler', value);
    state = state.copyWith(useOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs?.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _presetsBox?.put(preset.id, preset);
    state = state.copyWith(presets: _presetsBox!.values.toList());
  }

  void deletePreset(String id) {
    _presetsBox?.delete(id);
    final presets = _presetsBox!.values.toList();
    String activeId = state.activePresetId;

    if (activeId == id && presets.isNotEmpty) {
      activeId = presets.first.id;
      _prefs?.setString('activePresetId', activeId);
    }

    state = state.copyWith(
      presets: presets,
      activePresetId: activeId,
    );
  }
}
