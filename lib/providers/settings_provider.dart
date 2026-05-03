import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../core/constants.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  SettingsState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }

  CompilerPreset? get activePreset {
    if (useDefaultOneCompiler) {
      return presets.firstWhere((p) => p.id == 'onecompiler-default', orElse: () => presets.first);
    }
    return presets.firstWhere(
      (p) => p.id == activePresetId,
      orElse: () => presets.isNotEmpty ? presets.first : AppConstants.preloadedPresets.first,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _box;
  late SharedPreferences _prefs;

  SettingsNotifier() : super(SettingsState(
    presets: [],
    activePresetId: 'onecompiler-default',
    useDefaultOneCompiler: true,
  )) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>(AppConstants.hivePresetBox);
    _prefs = await SharedPreferences.getInstance();

    if (_box.isEmpty) {
      for (var preset in AppConstants.preloadedPresets) {
        await _box.put(preset.id, preset);
      }
    }

    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId') ?? 'onecompiler-default';

    state = SettingsState(
      presets: _box.values.toList(),
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void toggleUseDefault(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    _box.delete(id);
    final remaining = _box.values.toList();
    state = state.copyWith(
      presets: remaining,
      activePresetId: state.activePresetId == id
          ? (remaining.isNotEmpty ? remaining.first.id : '')
          : state.activePresetId,
    );
  }

  void duplicatePreset(CompilerPreset preset) {
      final newPreset = preset.copyWith(
          id: const Uuid().v4(),
          name: '${preset.name} (Copy)',
      );
      savePreset(newPreset);
  }

  Future<void> exportPresets(Function(String) onExport) async {
    final list = state.presets.map((p) => p.toJson()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(list);
    onExport(jsonStr);
  }

  Future<void> importPresets(String jsonStr) async {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        final preset = CompilerPreset.fromJson(item);
        // Regenerate ID to avoid conflicts on import
        final newPreset = preset.copyWith(id: const Uuid().v4());
        await _box.put(newPreset.id, newPreset);
      }
      state = state.copyWith(presets: _box.values.toList());
    } catch (e) {
      throw Exception('Invalid presets JSON');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
