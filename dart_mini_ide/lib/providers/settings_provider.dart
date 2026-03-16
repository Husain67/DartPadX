import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    this.useDefaultCompiler = true,
    this.activePresetId,
    this.presets = const [],
  });

  SettingsState copyWith({
    bool? useDefaultCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _presetBox;
  late SharedPreferences _prefs;

  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _presetBox = Hive.box<CompilerPreset>('presets');

    if (_presetBox.isEmpty) {
      _loadDefaultPresets();
    }

    final useDefault = _prefs.getBool('useDefaultCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    state = SettingsState(
      useDefaultCompiler: useDefault,
      activePresetId: activeId,
      presets: _presetBox.values.toList(),
    );
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler API',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'X-RapidAPI-Key': 'YOUR_API_KEY_HERE',
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle API',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston API',
        endpoint: 'https://emacs.piston.rs/api/v2/execute',
        method: 'POST',
        authType: 'None',
        headers: {
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'run.error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank Preset',
        endpoint: 'https://your-custom-api.com/execute',
        method: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      )
    ];

    for (var preset in defaultPresets) {
      _presetBox.put(preset.id, preset);
    }
  }

  Future<void> setUseDefaultCompiler(bool value) async {
    await _prefs.setBool('useDefaultCompiler', value);
    state = state.copyWith(useDefaultCompiler: value);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetBox.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    preset.save();
    state = state.copyWith(presets: _presetBox.values.toList());
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    state = state.copyWith(presets: _presetBox.values.toList());
  }
}
