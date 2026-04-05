
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> customPresets;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
    required this.customPresets,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? customPresets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      customPresets: customPresets ?? this.customPresets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true, customPresets: [])) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = prefs.getString('activePresetId');

    final box = Hive.box<CompilerPreset>('presetsBox');
    List<CompilerPreset> presets = box.values.toList();

    if (presets.isEmpty) {
      presets = Constants.defaultPresets;
      for (var p in presets) {
        box.put(p.id, p);
      }
    }

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      customPresets: presets,
    );
  }

  Future<void> toggleDefaultCompiler(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', val);
    state = state.copyWith(useDefaultOneCompiler: val);
  }

  Future<void> setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> addOrUpdatePreset(CompilerPreset preset) async {
    final box = Hive.box<CompilerPreset>('presetsBox');
    await box.put(preset.id, preset);
    state = state.copyWith(customPresets: box.values.toList());
  }

  Future<void> deletePreset(String id) async {
    final box = Hive.box<CompilerPreset>('presetsBox');
    await box.delete(id);

    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('activePresetId');
    }

    state = state.copyWith(customPresets: box.values.toList(), activePresetId: newActiveId);
  }

  CompilerPreset? getActivePreset() {
    if (state.useDefaultOneCompiler) {
      return state.customPresets.firstWhere(
        (p) => p.name == 'OneCompiler',
        orElse: () => Constants.defaultPresets[0]
      );
    }
    if (state.activePresetId != null) {
      try {
        return state.customPresets.firstWhere((p) => p.id == state.activePresetId);
      } catch (_) {}
    }
    return state.customPresets.isNotEmpty ? state.customPresets.first : null;
  }
}
