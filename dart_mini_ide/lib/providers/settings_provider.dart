import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String? selectedPresetId;
  final bool useOneCompiler;

  SettingsState({
    required this.presets,
    this.selectedPresetId,
    this.useOneCompiler = true,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? selectedPresetId,
    bool? useOneCompiler,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(presets: [])) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box(HiveService.settingsBoxName);
    final presetsBox = Hive.box<CompilerPreset>(HiveService.presetsBoxName);

    final useOneCompiler = box.get('useOneCompiler', defaultValue: true);
    final selectedId = box.get('selectedPresetId');

    state = SettingsState(
      presets: presetsBox.values.toList(),
      selectedPresetId: selectedId,
      useOneCompiler: useOneCompiler,
    );
  }

  Future<void> toggleCompiler(bool useOneCompiler) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('useOneCompiler', useOneCompiler);
    state = state.copyWith(useOneCompiler: useOneCompiler);
  }

  Future<void> selectPreset(String id) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('selectedPresetId', id);
    state = state.copyWith(selectedPresetId: id);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    final presetsBox = Hive.box<CompilerPreset>(HiveService.presetsBoxName);
    await presetsBox.add(preset);
    state = state.copyWith(presets: presetsBox.values.toList());
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await preset.save();
    final presetsBox = Hive.box<CompilerPreset>(HiveService.presetsBoxName);
    state = state.copyWith(presets: presetsBox.values.toList());
  }

  Future<void> deletePreset(CompilerPreset preset) async {
    await preset.delete();
    final presetsBox = Hive.box<CompilerPreset>(HiveService.presetsBoxName);
    state = state.copyWith(presets: presetsBox.values.toList());
  }
}
