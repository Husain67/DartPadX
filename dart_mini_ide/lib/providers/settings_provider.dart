import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../utils/constants.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  SettingsState({
    required this.presets,
    required this.activePresetId,
  });

  CompilerPreset get activePreset => presets.firstWhere(
        (preset) => preset.id == activePresetId,
        orElse: () => AppConstants.defaultPresets.first,
      );

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Box<CompilerPreset> _presetBox;
  final Box _settingsBox;

  SettingsNotifier(this._presetBox, this._settingsBox)
      : super(SettingsState(presets: [], activePresetId: '')) {
    _init();
  }

  void _init() {
    if (_presetBox.isEmpty) {
      for (final preset in AppConstants.defaultPresets) {
        _presetBox.put(preset.id, preset);
      }
    }

    final presets = _presetBox.values.toList();
    String? activeId = _settingsBox.get(AppConstants.activePresetIdKey);

    if (activeId == null || !presets.any((p) => p.id == activeId)) {
      activeId = AppConstants.defaultPresets.first.id;
      _settingsBox.put(AppConstants.activePresetIdKey, activeId);
    }

    state = SettingsState(presets: presets, activePresetId: activeId);
  }

  void setActivePreset(String id) {
    if (state.activePresetId == id) return;
    _settingsBox.put(AppConstants.activePresetIdKey, id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    final updatedPresets = List<CompilerPreset>.from(state.presets)..add(preset);
    state = state.copyWith(presets: updatedPresets);
  }

  void updatePreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      state.presets[index] = preset;
      state = state.copyWith(presets: List<CompilerPreset>.from(state.presets));
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newId = const Uuid().v4();
    final newPreset = CompilerPreset(
      id: newId,
      name: '${preset.name} Copy',
      endpointUrl: preset.endpointUrl,
      httpMethod: preset.httpMethod,
      authType: preset.authType,
      authValue: preset.authValue,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      bodyTemplate: preset.bodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      executionTimePath: preset.executionTimePath,
      memoryPath: preset.memoryPath,
      isDefault: false,
    );
    addPreset(newPreset);
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();

    String activeId = state.activePresetId;
    if (activeId == id && updatedPresets.isNotEmpty) {
      activeId = updatedPresets.first.id;
      _settingsBox.put(AppConstants.activePresetIdKey, activeId);
    }

    state = state.copyWith(presets: updatedPresets, activePresetId: activeId);
  }

  String exportPresets() {
    final presetsJson = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(presetsJson);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> presetsList = jsonDecode(jsonString);
      for (final presetJson in presetsList) {
        final preset = CompilerPreset.fromJson(presetJson as Map<String, dynamic>);
        addPreset(preset);
      }
    } catch (e) {
      print('Failed to import presets: $e');
    }
  }
}

final presetBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  return Hive.box<CompilerPreset>(AppConstants.presetBoxName);
});

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBoxName);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final presetBox = ref.watch(presetBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);
  return SettingsNotifier(presetBox, settingsBox);
});