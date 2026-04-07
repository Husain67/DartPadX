import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../services/preset_data.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    required this.presets,
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

  CompilerPreset? get activePreset {
    if (activePresetId == null || presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true, presets: [])) {
    _init();
  }

  late Box<CompilerPreset> _presetBox;
  late SharedPreferences _prefs;
  final _uuid = const Uuid();

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _presetBox = Hive.box<CompilerPreset>('compilerPresets');

    bool useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    String? activeId = _prefs.getString('activePresetId');

    var loadedPresets = _presetBox.values.toList();
    if (loadedPresets.isEmpty) {
      loadedPresets = PresetData.getPreloadedPresets();
      for (var p in loadedPresets) {
        await _presetBox.put(p.id, p);
      }
    }

    if (activeId == null && loadedPresets.isNotEmpty) {
      activeId = loadedPresets.first.id;
    }

    state = SettingsState(
      useDefaultOneCompiler: useDefault,
      presets: loadedPresets,
      activePresetId: activeId,
    );
  }

  void toggleDefaultCompiler(bool val) {
    _prefs.setBool('useDefaultOneCompiler', val);
    state = state.copyWith(useDefaultOneCompiler: val);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    final updated = _presetBox.values.toList();
    state = state.copyWith(presets: updated);
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = CompilerPreset(
      id: _uuid.v4(),
      name: '${preset.name} (Copy)',
      url: preset.url,
      method: preset.method,
      authType: preset.authType,
      authValue: preset.authValue,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      bodyTemplate: preset.bodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      timePath: preset.timePath,
      memoryPath: preset.memoryPath,
    );
    savePreset(newPreset);
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    final updated = _presetBox.values.toList();
    String? newActiveId = state.activePresetId == id
        ? (updated.isNotEmpty ? updated.first.id : null)
        : state.activePresetId;

    if (newActiveId != null) {
      _prefs.setString('activePresetId', newActiveId);
    } else {
      _prefs.remove('activePresetId');
    }

    state = SettingsState(
      useDefaultOneCompiler: state.useDefaultOneCompiler,
      presets: updated,
      activePresetId: newActiveId,
    );
  }

  Future<void> importPresets(List<CompilerPreset> newPresets) async {
    for (var p in newPresets) {
      await _presetBox.put(p.id, p);
    }
    state = state.copyWith(presets: _presetBox.values.toList());
  }
}
