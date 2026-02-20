import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import '../data/models/compiler_preset.dart';

final presetBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  return Hive.box<CompilerPreset>(AppConstants.presetBoxName);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, List<CompilerPreset>>((ref) {
  final box = ref.watch(presetBoxProvider);
  return SettingsNotifier(box);
});

class SettingsNotifier extends StateNotifier<List<CompilerPreset>> {
  final Box<CompilerPreset> _box;

  SettingsNotifier(this._box) : super(_box.values.toList()) {
    if (state.isEmpty) {
       final oneCompiler = CompilerPreset.oneCompiler();
       _box.put(oneCompiler.id, oneCompiler);
       state = _box.values.toList();
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = _box.values.toList();
    if (state.isEmpty) {
       final oneCompiler = CompilerPreset.oneCompiler();
       _box.put(oneCompiler.id, oneCompiler);
       state = _box.values.toList();
    }
  }
}

final activePresetIdProvider = StateProvider<String?>((ref) {
    // Should persist in shared prefs, but for simplicity default to onecompiler
    return 'onecompiler_default';
});

final activePresetProvider = Provider<CompilerPreset?>((ref) {
  final id = ref.watch(activePresetIdProvider);
  final presets = ref.watch(settingsProvider);
  try {
     return presets.firstWhere((p) => p.id == id);
  } catch (e) {
     if (presets.isNotEmpty) return presets.first;
     return null;
  }
});
