
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';
import 'hive_provider.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? currentPresetId;

  CompilerState({required this.presets, this.currentPresetId});

  CompilerState copyWith({List<CompilerPreset>? presets, String? currentPresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      currentPresetId: currentPresetId ?? this.currentPresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final HiveService _hiveService;

  CompilerNotifier(this._hiveService) : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    final presets = _hiveService.presetsBox.values.toList();
    final currentPresetId = _hiveService.prefs.getString(HiveService.currentPresetIdKey);
    state = CompilerState(presets: presets, currentPresetId: currentPresetId);
  }

  CompilerPreset? get currentPreset {
    if (state.currentPresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.currentPresetId);
    } catch (_) {
      return null;
    }
  }

  Future<void> switchPreset(String id) async {
    await _hiveService.prefs.setString(HiveService.currentPresetIdKey, id);

    final updatedPresets = state.presets.map((p) {
      if (p.id == id) return p.copyWith(isDefault: true);
      if (p.isDefault) return p.copyWith(isDefault: false);
      return p;
    }).toList();

    for (var preset in updatedPresets) {
      await _hiveService.presetsBox.put(preset.id, preset);
    }

    state = state.copyWith(presets: updatedPresets, currentPresetId: id);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _hiveService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _hiveService.presetsBox.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
  }

  Future<void> deletePreset(String id) async {
    await _hiveService.presetsBox.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: updatedPresets);
    if (state.currentPresetId == id && updatedPresets.isNotEmpty) {
      await switchPreset(updatedPresets.first.id);
    }
  }

  Future<void> exportPresets(String path) async {
    // Basic export implementation placeholder
  }

  Future<void> importPresets(String path) async {
    // Basic import implementation placeholder
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return CompilerNotifier(hiveService);
});
