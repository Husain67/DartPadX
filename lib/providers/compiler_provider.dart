import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  CompilerState({required this.presets, this.activePresetId});

  CompilerPreset? get activePreset => presets.firstWhere(
    (p) => p.id == activePresetId,
    orElse: () => presets.isNotEmpty ? presets.first : HiveService.getPreloadedPresets().first
  );

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final box = HiveService.presetBox;
    final prefs = await SharedPreferences.getInstance();

    if (box.isEmpty) {
      final preloaded = HiveService.getPreloadedPresets();
      for (var p in preloaded) {
        box.put(p.id, p);
      }
    }

    final savedActiveId = prefs.getString('activePresetId') ?? 'onecompiler';
    state = CompilerState(presets: box.values.toList(), activePresetId: savedActiveId);
  }

  void setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetBox.put(preset.id, preset);
    state = state.copyWith(presets: HiveService.presetBox.values.toList());
  }

  void deletePreset(String id) {
    HiveService.presetBox.delete(id);
    final remaining = HiveService.presetBox.values.toList();
    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = remaining.isNotEmpty ? remaining.first.id : null;
      if (newActiveId != null) setActivePreset(newActiveId);
    }
    state = state.copyWith(presets: remaining, activePresetId: newActiveId);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
