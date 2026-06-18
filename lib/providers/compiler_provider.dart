import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import '../core/hive_setup.dart';
import 'package:uuid/uuid.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  CompilerState({required this.presets, required this.activePresetId});

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _presetBox;
  final Box<dynamic> _settingsBox;

  CompilerNotifier(this._presetBox, this._settingsBox) : super(_initializeState(_presetBox, _settingsBox));

  static CompilerState _initializeState(Box<CompilerPreset> presetBox, Box<dynamic> settingsBox) {
    final presets = presetBox.values.toList();
    final activeId = settingsBox.get('active_preset_id', defaultValue: presets.firstWhere((p) => p.isDefault, orElse: () => presets.first).id);
    return CompilerState(presets: presets, activePresetId: activeId);
  }

  void setActivePreset(String id) {
    _settingsBox.put('active_preset_id', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetBox.values.toList());
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    final remaining = _presetBox.values.toList();
    String activeId = state.activePresetId;
    if (activeId == id && remaining.isNotEmpty) {
      activeId = remaining.first.id;
      _settingsBox.put('active_preset_id', activeId);
    }
    state = state.copyWith(presets: remaining, activePresetId: activeId);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final presetBox = Hive.box<CompilerPreset>(HiveSetup.presetsBoxName);
  final settingsBox = Hive.box<dynamic>(HiveSetup.settingsBoxName);
  return CompilerNotifier(presetBox, settingsBox);
});
