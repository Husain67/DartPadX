import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import '../models/preloaded_data.dart';

final compilerPresetsProvider = StateNotifierProvider<CompilerNotifier, List<CompilerPreset>>((ref) {
  return CompilerNotifier();
});

final activeCompilerPresetIdProvider = StateNotifierProvider<ActiveCompilerNotifier, String>((ref) {
  return ActiveCompilerNotifier();
});

final activeCompilerPresetProvider = Provider<CompilerPreset>((ref) {
  final presets = ref.watch(compilerPresetsProvider);
  final activeId = ref.watch(activeCompilerPresetIdProvider);
  return presets.firstWhere((p) => p.id == activeId, orElse: () => PreloadedData.presets.first);
});

class CompilerNotifier extends StateNotifier<List<CompilerPreset>> {
  late Box<CompilerPreset> _box;

  CompilerNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>('presetsBox');
    if (_box.isEmpty) {
      for (final preset in PreloadedData.presets) {
        await _box.put(preset.id, preset);
      }
    }
    state = _box.values.toList();
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset);
    state = [...state, preset];
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset);
    state = state.map((p) => p.id == preset.id ? preset : p).toList();
  }

  Future<void> deletePreset(String id) async {
    await _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }
}

class ActiveCompilerNotifier extends StateNotifier<String> {
  late SharedPreferences _prefs;
  static const _key = 'activeCompilerId';

  ActiveCompilerNotifier() : super('default_onecompiler') {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final id = _prefs.getString(_key);
    if (id != null) {
      state = id;
    }
  }

  Future<void> setActive(String id) async {
    await _prefs.setString(_key, id);
    state = id;
  }
}
