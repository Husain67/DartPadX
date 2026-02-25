import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, CompilerPreset>((ref) {
  return SettingsNotifier();
});

final allPresetsProvider = Provider<List<CompilerPreset>>((ref) {
  final box = Hive.box<CompilerPreset>('compiler_presets');
  return box.values.toList();
});

class SettingsNotifier extends StateNotifier<CompilerPreset> {
  SettingsNotifier() : super(CompilerPreset.oneCompiler()) {
    _loadSettings();
  }

  late Box<CompilerPreset> _box;
  late Box _settingsBox;

  Future<void> _loadSettings() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    _settingsBox = await Hive.openBox('settings');

    // Initialize default if empty
    if (_box.isEmpty) {
      await _box.add(CompilerPreset.oneCompiler());
    }

    final selectedId = _settingsBox.get('selected_preset_id');
    if (selectedId != null) {
      final preset = _box.values.firstWhere(
        (p) => p.id == selectedId,
        orElse: () => _box.values.first,
      );
      state = preset;
    } else {
      state = _box.values.first;
    }
  }

  Future<void> selectPreset(String id) async {
    final preset = _box.values.firstWhere(
      (p) => p.id == id,
      orElse: () => state,
    );
    state = preset;
    await _settingsBox.put('selected_preset_id', id);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.add(preset);
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await preset.save();
    if (state.id == preset.id) {
      state = preset; // Refresh state
    }
  }

  Future<void> deletePreset(String id) async {
    final preset = _box.values.firstWhere((p) => p.id == id);
    if (preset.isDefault) return; // Prevent deleting default
    await preset.delete();
    if (state.id == id) {
      state = _box.values.first;
      await _settingsBox.put('selected_preset_id', state.id);
    }
  }
}
