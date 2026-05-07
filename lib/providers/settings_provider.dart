import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  SettingsState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
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
    if (activePresetId == null) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _boxName = 'dartmini_presets';
  late Box _box;
  late SharedPreferences _prefs;

  SettingsNotifier() : super(SettingsState(presets: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);
    _prefs = await SharedPreferences.getInstance();

    final useDefault = _prefs.getBool('use_default_onecompiler') ?? true;
    final activeId = _prefs.getString('active_preset_id');

    List<CompilerPreset> loadedPresets = [];
    for (var key in _box.keys) {
      final map = _box.get(key);
      if (map != null && map is Map) {
        loadedPresets.add(CompilerPreset.fromMap(map));
      }
    }

    if (loadedPresets.isEmpty) {
      final defaultOneCompiler = CompilerPreset(
        name: 'OneCompiler (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: [
          const MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com'),
          const MapEntry('Content-Type', 'application/json'),
        ],
        queryParams: [],
        requestBodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ]
}''',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isDefault: true,
      );
      loadedPresets.add(defaultOneCompiler);
      await _box.put(defaultOneCompiler.id, defaultOneCompiler.toMap());
    }

    state = SettingsState(
      presets: loadedPresets,
      activePresetId: activeId ?? (loadedPresets.isNotEmpty ? loadedPresets.first.id : null),
      useDefaultOneCompiler: useDefault,
    );
  }

  void toggleUseDefault(bool value) {
    _prefs.setBool('use_default_onecompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('active_preset_id', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    final newPresets = [...state.presets, preset];
    _box.put(preset.id, preset.toMap());
    state = state.copyWith(presets: newPresets, activePresetId: preset.id);
    _prefs.setString('active_preset_id', preset.id);
  }

  void updatePreset(CompilerPreset preset) {
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    _box.put(preset.id, preset.toMap());
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    final newPresets = state.presets.where((p) => p.id != id).toList();
    _box.delete(id);

    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : null;
      if (newActiveId != null) {
        _prefs.setString('active_preset_id', newActiveId);
      } else {
        _prefs.remove('active_preset_id');
      }
    }

    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)',
      isDefault: false,
    );
    addPreset(newPreset);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
