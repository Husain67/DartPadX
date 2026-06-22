import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }

  CompilerPreset? get activePreset {
    if (activePresetId == null || presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (e) {
      return null;
    }
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;

  CompilerNotifier(this._box) : super(CompilerState(presets: _box.values.toList())) {
    if (state.presets.isEmpty) {
      _loadPreloadedPresets();
    } else {
      _initActivePreset();
    }
  }

  void _initActivePreset() {
    try {
      final defaultPreset = state.presets.firstWhere((p) => p.isDefault);
      state = state.copyWith(activePresetId: defaultPreset.id, useDefaultOneCompiler: defaultPreset.id == 'onecompiler_default');
    } catch (e) {
      if (state.presets.isNotEmpty) {
         state = state.copyWith(activePresetId: state.presets.first.id);
      }
    }
  }

  void _loadPreloadedPresets() {
    final defaultOneCompiler = CompilerPreset(
      id: 'onecompiler_default',
      name: 'OneCompiler (Default)',
      endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      headers: {
        'X-RapidAPI-Key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
      isDefault: true,
      isPreloaded: true,
    );

    final piston = CompilerPreset(
      id: 'piston_public',
      name: 'Piston (Public API)',
      endpoint: 'https://emacsx.com/api/v2/execute',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'compile.stderr',
      executionTimePath: '',
      memoryPath: '',
      isDefault: false,
      isPreloaded: true,
    );

    final blank = CompilerPreset(
      id: 'blank_preset',
      name: 'Blank',
      endpoint: '',
      httpMethod: 'POST',
      authType: 'None',
      headers: {},
      queryParams: {},
      bodyTemplate: '{}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
      isDefault: false,
      isPreloaded: true,
    );

    final preloaded = [defaultOneCompiler, piston, blank];
    for (var preset in preloaded) {
      _box.put(preset.id, preset);
    }

    state = CompilerState(presets: preloaded, activePresetId: defaultOneCompiler.id, useDefaultOneCompiler: true);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: newPresets);
    if (state.activePresetId == id) {
       _initActivePreset();
    }
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id, useDefaultOneCompiler: id == 'onecompiler_default');
  }

  void setGlobalDefaultOneCompiler(bool useDefault) {
    state = state.copyWith(useDefaultOneCompiler: useDefault);
    if (useDefault) {
       setActivePreset('onecompiler_default');
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('compilers');
  return CompilerNotifier(box);
});
