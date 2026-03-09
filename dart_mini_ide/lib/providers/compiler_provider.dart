
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  CompilerState({required this.presets, this.activePresetId});

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> presetBox;

  CompilerNotifier(this.presetBox) : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    final storedPresets = presetBox.values.toList();
    if (storedPresets.isEmpty) {
      final defaultPresets = CompilerPreset.getDefaultPresets();
      for (var p in defaultPresets) {
        presetBox.put(p.id, p);
      }
      state = CompilerState(presets: defaultPresets, activePresetId: defaultPresets.first.id);
    } else {
      // Find oneCompiler if available
      final oneCompiler = storedPresets.firstWhere(
        (p) => p.name.toLowerCase().contains('onecompiler'),
        orElse: () => storedPresets.first,
      );
      state = CompilerState(presets: storedPresets, activePresetId: oneCompiler.id);
    }
  }

  void addPreset(CompilerPreset preset) {
    presetBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    presetBox.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    presetBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();

    String? newActiveId = state.activePresetId;
    if (id == state.activePresetId && newPresets.isNotEmpty) {
      newActiveId = newPresets.first.id;
    }

    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)',
    );
    addPreset(newPreset);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    return state.presets.firstWhere(
      (p) => p.id == state.activePresetId,
      orElse: () => state.presets.first,
    );
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('compilerPresets');
  return CompilerNotifier(box);
});
