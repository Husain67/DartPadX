import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String selectedPresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultOneCompiler,
    required this.selectedPresetId,
    required this.presets,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? selectedPresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _box;
  late Box _prefsBox;

  SettingsNotifier()
      : super(SettingsState(
          useDefaultOneCompiler: true,
          selectedPresetId: 'onecompiler_default',
          presets: [],
        )) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>(AppConstants.settingsBoxName);
    _prefsBox = Hive.box('prefs');

    bool useDefault = _prefsBox.get('useDefaultOneCompiler', defaultValue: true);
    String selectedId = _prefsBox.get('selectedPresetId', defaultValue: 'onecompiler_default');

    if (_box.isEmpty) {
      for (var p in AppConstants.preloadedPresets) {
        await _box.put(p.id, p);
      }
    }

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      selectedPresetId: selectedId,
      presets: _box.values.toList(),
    );
  }

  CompilerPreset get activePreset {
    if (state.useDefaultOneCompiler) {
      return AppConstants.oneCompilerDefault;
    }
    return state.presets.firstWhere(
      (p) => p.id == state.selectedPresetId,
      orElse: () => AppConstants.oneCompilerDefault,
    );
  }

  void toggleUseDefault(bool val) {
    _prefsBox.put('useDefaultOneCompiler', val);
    state = state.copyWith(useDefaultOneCompiler: val);
  }

  void selectPreset(String id) {
    _prefsBox.put('selectedPresetId', id);
    state = state.copyWith(selectedPresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void duplicatePreset(CompilerPreset preset) {
    final newId = const Uuid().v4();
    final newPreset = preset.copyWith(
      id: newId,
      platformName: '\${preset.platformName} (Copy)',
    );
    addPreset(newPreset);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    if (id == 'onecompiler_default') return; // protect default
    _box.delete(id);
    String newSelectedId = state.selectedPresetId == id ? 'onecompiler_default' : state.selectedPresetId;
    _prefsBox.put('selectedPresetId', newSelectedId);
    state = state.copyWith(presets: _box.values.toList(), selectedPresetId: newSelectedId);
  }

  void replaceAllPresets(List<CompilerPreset> newPresets) async {
    await _box.clear();
    for (var p in newPresets) {
      await _box.put(p.id, p);
    }
    state = state.copyWith(presets: _box.values.toList());
  }
}
