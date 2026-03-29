import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _box;
  late SharedPreferences _prefs;

  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: '', useDefaultOneCompiler: true)) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    if (_box.isEmpty) {
      for (var preset in AppConstants.predefinedPresets) {
        await _box.put(preset.id, preset);
      }
    }

    final presets = _box.values.toList();
    final activeId = _prefs.getString('activePresetId') ?? presets.first.id;
    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;

    state = SettingsState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void setUseDefaultOneCompiler(bool useDefault) {
    _prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final updatedPresets = List<CompilerPreset>.from(state.presets);
      updatedPresets[index] = preset;
      state = state.copyWith(presets: updatedPresets);
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      name: '${preset.name} Copy',
      endpointUrl: preset.endpointUrl,
      httpMethod: preset.httpMethod,
      authType: preset.authType,
      authKey: preset.authKey,
      authValue: preset.authValue,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      requestBodyTemplate: preset.requestBodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      executionTimePath: preset.executionTimePath,
      memoryPath: preset.memoryPath,
    );
    addPreset(newPreset);
  }

  void deletePreset(String id) {
    if (state.presets.length <= 1) return;

    _box.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();

    String newActiveId = state.activePresetId;
    if (id == state.activePresetId) {
      newActiveId = updatedPresets.first.id;
      _prefs.setString('activePresetId', newActiveId);
    }

    state = SettingsState(
      presets: updatedPresets,
      activePresetId: newActiveId,
      useDefaultOneCompiler: state.useDefaultOneCompiler,
    );
  }

  String exportPresets() {
    final List<Map<String, dynamic>> jsonList = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(jsonList);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (var json in jsonList) {
        final preset = CompilerPreset.fromJson(json as Map<String, dynamic>);
        // Create new ID to avoid conflicts if they already exist
        final newPreset = CompilerPreset(
          id: const Uuid().v4(),
          name: '${preset.name} (Imported)',
          endpointUrl: preset.endpointUrl,
          httpMethod: preset.httpMethod,
          authType: preset.authType,
          authKey: preset.authKey,
          authValue: preset.authValue,
          headers: preset.headers,
          queryParams: preset.queryParams,
          requestBodyTemplate: preset.requestBodyTemplate,
          stdoutPath: preset.stdoutPath,
          stderrPath: preset.stderrPath,
          errorPath: preset.errorPath,
          executionTimePath: preset.executionTimePath,
          memoryPath: preset.memoryPath,
        );
        _box.put(newPreset.id, newPreset);
      }
      state = state.copyWith(presets: _box.values.toList());
    } catch (e) {
      // Handle error, maybe show toast
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
