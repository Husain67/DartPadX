import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  SettingsState({required this.presets, required this.activePresetId});

  CompilerPreset get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (e) {
      return CompilerPreset.defaultOneCompiler();
    }
  }

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Box<CompilerPreset> _presetsBox = Hive.box<CompilerPreset>('compiler_presets');
  final Box _settingsBox = Hive.box('settings');

  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: '')) {
    _init();
  }

  void _init() {
    List<CompilerPreset> loadedPresets = _presetsBox.values.toList();
    if (loadedPresets.isEmpty) {
      final defaultPreset = CompilerPreset.defaultOneCompiler();
      _presetsBox.putAll({for (var p in CompilerPreset.getDefaultPresets()) p.id: p});
      loadedPresets = _presetsBox.values.toList();
      _presetsBox.put(defaultPreset.id, defaultPreset);
      loadedPresets = CompilerPreset.getDefaultPresets();
    }

    String activeId = _settingsBox.get('active_preset_id', defaultValue: 'onecompiler_default');
    if (!loadedPresets.any((p) => p.id == activeId)) {
      activeId = loadedPresets.first.id;
      _settingsBox.put('active_preset_id', activeId);
    }

    state = SettingsState(presets: loadedPresets, activePresetId: activeId);
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    if (id == 'onecompiler_default') return; // Cannot delete default
    _presetsBox.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();

    String newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = 'onecompiler_default';
      _settingsBox.put('active_preset_id', newActiveId);
    }

    state = state.copyWith(presets: updatedPresets, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    if (state.presets.any((p) => p.id == id)) {
      _settingsBox.put('active_preset_id', id);
      state = state.copyWith(activePresetId: id);
    }
  }

  void duplicatePreset(String id) {
    try {
      final presetToDuplicate = state.presets.firstWhere((p) => p.id == id);
      final newPreset = presetToDuplicate.copyWith(
        id: const Uuid().v4(),
        name: '${presetToDuplicate.name} (Copy)',
      );
      addPreset(newPreset);
    } catch (e) {
      // Ignored
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
