import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    this.useDefaultOneCompiler = true,
    this.activePresetId,
    this.presets = const [],
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    final box = HiveService.presetsBox;
    final presets = box.values.toList();

    if (presets.isEmpty) {
      _loadDefaultPresets();
      return;
    }

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      presets: presets,
    );
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': '{authValue}',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
      ),
      CompilerPreset(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        bodyTemplate: '{\n  "clientId": "{authValue1}",\n  "clientSecret": "{authValue2}",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        memoryPath: 'memory',
        executionTimePath: 'cpuTime',
      ),
      CompilerPreset(
        name: 'Piston',
        endpointUrl: 'https://emacsx.com/api/v2/execute',
        httpMethod: 'POST',
        bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        name: 'Replit',
        endpointUrl: '',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        name: 'CodeX',
        endpointUrl: '',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        name: 'HackerEarth',
        endpointUrl: '',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
      ),
    ];

    final box = HiveService.presetsBox;
    for (var preset in defaultPresets) {
      box.put(preset.id, preset);
    }

    state = state.copyWith(
      useDefaultOneCompiler: true,
      activePresetId: null,
      presets: defaultPresets,
    );
    _prefs.setBool('useDefaultOneCompiler', true);
  }

  void toggleDefaultOneCompiler(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String? id) {
    if (id != null) {
      _prefs.setString('activePresetId', id);
    } else {
      _prefs.remove('activePresetId');
    }
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();

    if (state.activePresetId == id) {
      setActivePreset(null);
      toggleDefaultOneCompiler(true);
    }

    state = state.copyWith(presets: updatedPresets);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPrefsProvider in main.dart');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
