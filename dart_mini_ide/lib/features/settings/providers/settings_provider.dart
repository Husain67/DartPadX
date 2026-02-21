import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId; // null means Default OneCompiler
  final bool isLoading;

  SettingsState({
    this.presets = const [],
    this.activePresetId,
    this.isLoading = true,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? isLoading,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  late Box<CompilerPreset> _presetsBox;
  late Box _settingsBox;

  Future<void> _loadSettings() async {
    _presetsBox = Hive.box<CompilerPreset>('presets');
    _settingsBox = Hive.box('settings');

    final presets = _presetsBox.values.toList();
    final activeId = _settingsBox.get('activePresetId') as String?;

    state = state.copyWith(
      presets: presets,
      activePresetId: activeId,
      isLoading: false,
    );
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newPresets = [...state.presets];
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    }
  }

  Future<void> deletePreset(String id) async {
    await _presetsBox.delete(id);
    state = state.copyWith(
      presets: state.presets.where((p) => p.id != id).toList(),
      activePresetId: state.activePresetId == id ? null : state.activePresetId,
    );
    if (state.activePresetId == id) {
      await _settingsBox.delete('activePresetId');
    }
  }

  Future<void> setActivePreset(String? id) async {
    if (id == null) {
      await _settingsBox.delete('activePresetId');
    } else {
      await _settingsBox.put('activePresetId', id);
    }
    state = state.copyWith(activePresetId: id);
  }
}
