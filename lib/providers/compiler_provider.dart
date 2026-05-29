import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset_model.dart';
import '../utils/hive_setup.dart';

class CompilerState {
  final List<CompilerPresetModel> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
  });

  CompilerState copyWith({
    List<CompilerPresetModel>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _init();
  }

  void _init() {
    final box = HiveSetup.presetsBox;
    final settingsBox = HiveSetup.settingsBox;

    if (box.isEmpty) {
      _loadInitialPresets();
    }

    final presets = box.values.toList();
    final bool useDefault = settingsBox.get('useDefaultOneCompiler', defaultValue: true);
    final String? activeId = settingsBox.get('activePresetId');

    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void _loadInitialPresets() {
    final defaultPresets = [
      CompilerPresetModel(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: [
          {'key': 'x-rapidapi-key', 'value': const String.fromEnvironment('API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac')},
          {'key': 'Content-Type', 'value': 'application/json'},
        ],
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
        isBuiltIn: true,
      ),
      CompilerPresetModel(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: [{'key': 'Content-Type', 'value': 'application/json'}],
        bodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "0", "clientId": "YOUR_ID", "clientSecret": "YOUR_SECRET"}',
        stdoutPath: 'output',
        timePath: 'cpuTime',
        memoryPath: 'memory',
        isBuiltIn: true,
      ),
      CompilerPresetModel(name: 'Piston', endpointUrl: 'https://emacs.piston.rs/api/v2/execute', isBuiltIn: true),
      CompilerPresetModel(name: 'Replit', endpointUrl: '', isBuiltIn: true),
      CompilerPresetModel(name: 'CodeX', endpointUrl: '', isBuiltIn: true),
      CompilerPresetModel(name: 'HackerEarth', endpointUrl: '', isBuiltIn: true),
      CompilerPresetModel(name: 'Blank', endpointUrl: '', isBuiltIn: true),
    ];

    for (var preset in defaultPresets) {
      HiveSetup.presetsBox.put(preset.id, preset);
    }
  }

  void addPreset(CompilerPresetModel preset) {
    HiveSetup.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPresetModel preset) {
    HiveSetup.presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newList = List<CompilerPresetModel>.from(state.presets);
      newList[index] = preset;
      state = state.copyWith(presets: newList);
    }
  }

  void deletePreset(String id) {
    HiveSetup.presetsBox.delete(id);
    final newList = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: newList);
    if (state.activePresetId == id) {
      setActivePreset(null);
    }
  }

  void setActivePreset(String? id) {
    HiveSetup.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void setUseDefaultOneCompiler(bool value) {
    HiveSetup.settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  CompilerPresetModel? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
