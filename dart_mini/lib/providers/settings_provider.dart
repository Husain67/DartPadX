import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/preset_model.dart';
import 'hive_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = prefs.getString('activePresetId') ?? 'oc_default';
    state = state.copyWith(useDefaultOneCompiler: useDefault, activePresetId: activeId);
  }

  Future<void> setUseDefaultOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  Future<void> setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id, useDefaultOneCompiler: false);
    await prefs.setBool('useDefaultOneCompiler', false);
  }

  CompilerPreset? getActivePreset() {
    if (state.useDefaultOneCompiler) {
      return HiveService.presetsBox.get('oc_default');
    }
    return HiveService.presetsBox.get(state.activePresetId);
  }

  List<CompilerPreset> getAllPresets() {
    return HiveService.presetsBox.values.toList();
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    // Force UI refresh if modifying active
    if (state.activePresetId == preset.id) {
        state = state.copyWith();
    }
  }

  void deletePreset(String id) {
    if (id == 'oc_default') return; // protect default
    HiveService.presetsBox.delete(id);
    if (state.activePresetId == id) {
      setActivePreset('oc_default');
    }
  }

  String exportPresets() {
    final presets = getAllPresets().map((p) => p.toJson()).toList();
    return jsonEncode(presets);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> data = jsonDecode(jsonString);
      for (var item in data) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        HiveService.presetsBox.put(preset.id, preset);
      }
    } catch (e) {
      debugPrint('Import failed: $e');
    }
  }
}
