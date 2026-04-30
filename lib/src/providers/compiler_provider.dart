import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/hive_storage_service.dart';
import '../services/preferences_service.dart';


class CompilerState {
  final List<CompilerPreset> presets;
  final bool useDefaultOneCompiler;
  final String? selectedPresetId;

  CompilerState({
    required this.presets,
    required this.useDefaultOneCompiler,
    this.selectedPresetId,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefaultOneCompiler,
    String? selectedPresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier()
      : super(CompilerState(
          presets: [],
          useDefaultOneCompiler: PreferencesService.useDefaultOneCompiler,
          selectedPresetId: PreferencesService.selectedPresetId,
        )) {
    _loadPresets();
  }

  void _loadPresets() {
    final box = HiveStorageService.presetsBox;
    final presets = box.values.toList();

    String? selectedId = state.selectedPresetId;
    if (selectedId != null && !presets.any((p) => p.id == selectedId)) {
        selectedId = null;
    }
    if (selectedId == null && presets.isNotEmpty) {
      selectedId = presets.first.id;
    }

    state = state.copyWith(presets: presets, selectedPresetId: selectedId);
  }

  void toggleUseDefault(bool value) {
    PreferencesService.setUseDefaultOneCompiler(value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setSelectedPreset(String id) {
    PreferencesService.setSelectedPresetId(id);
    state = state.copyWith(selectedPresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    HiveStorageService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    HiveStorageService.presetsBox.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    HiveStorageService.presetsBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();

    String? newSelectedId = state.selectedPresetId;
    if (newSelectedId == id) {
      newSelectedId = newPresets.isNotEmpty ? newPresets.first.id : null;
      if(newSelectedId != null) PreferencesService.setSelectedPresetId(newSelectedId);
    }

    state = state.copyWith(presets: newPresets, selectedPresetId: newSelectedId);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
