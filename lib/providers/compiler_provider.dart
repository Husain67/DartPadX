import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
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
    } catch (_) {
      return null;
    }
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  CompilerNotifier(this._box) : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  CompilerState get currentState => state;

  void _loadPresets() {
    final presets = _box.values.toList();
    if (presets.isEmpty) {
      _initializeDefaultPresets();
      return;
    }
    // Also load the boolean choice from somewhere, ideally SharedPreferences,
    // but for now we default to true if it's a fresh load.
    state = CompilerState(
      presets: presets,
      activePresetId: presets.first.id,
      useDefaultOneCompiler: true,
    );
  }

  void _initializeDefaultPresets() {
    final initialPresets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'x-rapidapi-key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None', // Uses body params usually
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      )
    ];

    for (var p in initialPresets) {
      _box.put(p.id, p);
    }

    state = CompilerState(
      presets: initialPresets,
      activePresetId: initialPresets.first.id,
      useDefaultOneCompiler: true,
    );
  }

  void toggleUseDefault(bool useDefault) {
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(id: _uuid.v4());
    _box.put(newPreset.id, newPreset);
    state = state.copyWith(
      presets: [...state.presets, newPreset],
      activePresetId: newPreset.id,
    );
  }

  void updatePreset(CompilerPreset updatedPreset) {
    _box.put(updatedPreset.id, updatedPreset);
    final newPresets = state.presets.map((p) => p.id == updatedPreset.id ? updatedPreset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = List<CompilerPreset>.from(state.presets)..removeWhere((p) => p.id == id);
    String? newActiveId = state.activePresetId;
    if (newActiveId == id && newPresets.isNotEmpty) {
      newActiveId = newPresets.first.id;
    } else if (newPresets.isEmpty) {
      newActiveId = null;
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('presets');
  return CompilerNotifier(box);
});
