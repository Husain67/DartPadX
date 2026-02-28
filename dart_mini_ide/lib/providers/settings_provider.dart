import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefault;

  SettingsState({
    required this.presets,
    required this.activePresetId,
    this.useDefault = true,
  });

  CompilerPreset get activePreset {
    if (useDefault) {
      return CompilerPreset.defaultPreset();
    }
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return CompilerPreset.defaultPreset();
    }
  }

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefault,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefault: useDefault ?? this.useDefault,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _box;
  late SharedPreferences _prefs;

  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: 'default_onecompiler')) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    final useDefault = _prefs.getBool('use_default_compiler') ?? true;
    final activeId = _prefs.getString('active_preset_id') ?? 'default_onecompiler';

    List<CompilerPreset> savedPresets = _box.values.toList();
    if (savedPresets.isEmpty) {
      final preset = CompilerPreset.defaultPreset();
      await _box.put(preset.id, preset);
      savedPresets = [preset];
    }

    state = SettingsState(
      presets: savedPresets,
      activePresetId: activeId,
      useDefault: useDefault,
    );
  }

  Future<void> toggleUseDefault(bool value) async {
    await _prefs.setBool('use_default_compiler', value);
    state = state.copyWith(useDefault: value);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString('active_preset_id', id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await preset.save();
    state = state.copyWith(presets: _box.values.toList());
  }

  Future<void> deletePreset(String id) async {
    await _box.delete(id);
    final newPresets = _box.values.toList();

    if (state.activePresetId == id) {
      final newActiveId = newPresets.isNotEmpty ? newPresets.first.id : 'default_onecompiler';
      await setActivePreset(newActiveId);
    }

    state = state.copyWith(presets: newPresets);
  }
}
