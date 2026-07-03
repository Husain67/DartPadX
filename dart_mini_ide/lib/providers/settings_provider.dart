import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultCompiler;

  SettingsState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultCompiler,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultCompiler,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: '', useDefaultCompiler: true)) {
    _loadSettings();
  }

  final Box _presetsBox = Hive.box('presets');
  final Box _settingsBox = Hive.box('settings');

  void _loadSettings() {
    final Map<dynamic, dynamic> data = _presetsBox.toMap();
    final List<CompilerPreset> loadedPresets = [];

    data.forEach((key, value) {
      try {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(value);
        loadedPresets.add(CompilerPreset.fromJson(jsonMap));
      } catch (e) {
        // Ignore invalid entries
      }
    });

    if (loadedPresets.isEmpty) {
      const String defaultApiKey = String.fromEnvironment('RAPIDAPI_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');
      final defaultPreset = CompilerPreset(
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'Header',
        headers: {
          'X-RapidAPI-Key': defaultApiKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
        memoryPath: '',
      );
      loadedPresets.add(defaultPreset);
      _presetsBox.put(defaultPreset.id, defaultPreset.toJson());
    }

    final activePresetId = _settingsBox.get('activePresetId', defaultValue: loadedPresets.first.id);
    final useDefaultCompiler = _settingsBox.get('useDefaultCompiler', defaultValue: true);

    state = SettingsState(
      presets: loadedPresets,
      activePresetId: activePresetId,
      useDefaultCompiler: useDefaultCompiler,
    );
  }

  void addPreset(CompilerPreset preset) {
    final updatedPresets = [...state.presets, preset];
    state = state.copyWith(presets: updatedPresets);
    _presetsBox.put(preset.id, preset.toJson());
  }

  void updatePreset(CompilerPreset preset) {
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
    _presetsBox.put(preset.id, preset.toJson());
  }

  void deletePreset(String id) {
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: updatedPresets);
    _presetsBox.delete(id);
    if (state.activePresetId == id && updatedPresets.isNotEmpty) {
      setActivePreset(updatedPresets.first.id);
    }
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
    _settingsBox.put('activePresetId', id);
  }

  void setUseDefaultCompiler(bool useDefault) {
    state = state.copyWith(useDefaultCompiler: useDefault);
    _settingsBox.put('useDefaultCompiler', useDefault);
  }
}
