import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _presetsBox;
  final Box _settingsBox;

  CompilerNotifier(this._presetsBox, this._settingsBox) : super(CompilerState(presets: [])) {
    _loadState();
  }

  CompilerState get currentState => state;

  void _loadState() {
    final presets = _presetsBox.values.toList();
    final activeId = _settingsBox.get('activePresetId');
    final useDefault = _settingsBox.get('useDefaultOneCompiler', defaultValue: true);

    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void setUseDefaultOneCompiler(bool value) {
    _settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final updatedPresets = [...state.presets, preset];
    state = state.copyWith(presets: updatedPresets);
  }

  void updatePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final updatedPresets = List<CompilerPreset>.from(state.presets);
      updatedPresets[index] = preset;
      state = state.copyWith(presets: updatedPresets);
    }
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    String? activeId = state.activePresetId;
    if (activeId == id) {
      activeId = updatedPresets.isNotEmpty ? updatedPresets.first.id : null;
      _settingsBox.put('activePresetId', activeId);
    }
    state = state.copyWith(presets: updatedPresets, activePresetId: activeId);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (e) {
      return null;
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final presetsBox = Hive.box<CompilerPreset>(HiveService.presetsBoxName);
  final settingsBox = Hive.box(HiveService.settingsBoxName);
  return CompilerNotifier(presetsBox, settingsBox);
});
