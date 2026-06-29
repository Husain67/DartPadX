import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../main.dart'; // For sharedPreferencesProvider

class PresetState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultCompiler; // OneCompiler vs Selected Preset

  PresetState({
    required this.presets,
    this.activePresetId,
    this.useDefaultCompiler = true,
  });

  PresetState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultCompiler,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  final SharedPreferences prefs;
  static const String _presetsKey = 'compiler_presets';
  static const String _activePresetIdKey = 'active_preset_id';
  static const String _useDefaultCompilerKey = 'use_default_compiler';

  PresetNotifier(this.prefs) : super(PresetState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    List<CompilerPreset> loadedPresets = [];
    final presetsJson = prefs.getStringList(_presetsKey);

    if (presetsJson != null && presetsJson.isNotEmpty) {
      loadedPresets = presetsJson.map((e) => CompilerPreset.fromJson(e)).toList();
    } else {
      // Load Defaults
      loadedPresets = [
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'JDoodle (Example)',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '''{
  "clientId": "your_client_id",
  "clientSecret": "your_client_secret",
  "script": "{code}",
  "language": "dart",
  "versionIndex": "0"
}''',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'statusCode',
          timePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'Blank Custom API',
          endpointUrl: '',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {},
          queryParams: {},
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          timePath: '',
          memoryPath: '',
        )
      ];
      _savePresetsList(loadedPresets);
    }

    final activeId = prefs.getString(_activePresetIdKey);
    final useDefault = prefs.getBool(_useDefaultCompilerKey) ?? true;

    state = PresetState(
      presets: loadedPresets,
      activePresetId: activeId ?? (loadedPresets.isNotEmpty ? loadedPresets.first.id : null),
      useDefaultCompiler: useDefault,
    );
  }

  void _savePresetsList(List<CompilerPreset> list) {
    prefs.setStringList(_presetsKey, list.map((e) => e.toJson()).toList());
  }

  void addPreset(CompilerPreset preset) {
    final newList = [...state.presets, preset];
    _savePresetsList(newList);
    state = state.copyWith(presets: newList);
  }

  void updatePreset(CompilerPreset preset) {
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index == -1) return;

    final newList = List<CompilerPreset>.from(state.presets);
    newList[index] = preset;
    _savePresetsList(newList);
    state = state.copyWith(presets: newList);
  }

  void deletePreset(String id) {
    final newList = state.presets.where((p) => p.id != id).toList();
    _savePresetsList(newList);

    String? newActiveId = state.activePresetId;
    if (id == state.activePresetId) {
      newActiveId = newList.isNotEmpty ? newList.first.id : null;
      if (newActiveId != null) {
         prefs.setString(_activePresetIdKey, newActiveId);
      } else {
         prefs.remove(_activePresetIdKey);
      }
    }

    state = state.copyWith(presets: newList, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    prefs.setString(_activePresetIdKey, id);
    state = state.copyWith(activePresetId: id);
  }

  void toggleUseDefaultCompiler(bool useDefault) {
    prefs.setBool(_useDefaultCompilerKey, useDefault);
    state = state.copyWith(useDefaultCompiler: useDefault);
  }
}

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PresetNotifier(prefs);
});
