
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dartmini_ide/src/features/settings/domain/compiler_preset.dart';
import 'package:dartmini_ide/src/core/providers/storage_provider.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    this.presets = const [],
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
  final StorageService _storage;
  final _uuid = const Uuid();

  CompilerNotifier(this._storage) : super(CompilerState()) {
    _loadPresets();
  }

  void _loadPresets() {
    final boxPresets = _storage.presetBox.values.toList();
    if (boxPresets.isEmpty) {
      _initializePreloadedPresets();
    } else {
      state = state.copyWith(
        presets: boxPresets,
        activePresetId: boxPresets.isNotEmpty ? boxPresets.first.id : null,
      );
    }
  }

  void _initializePreloadedPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isPreloaded: true,
      ),

      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
        isPreloaded: true,
      ),

      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "0", "clientId": "", "clientSecret": ""}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emacs.io/api/v2/execute', // Example endpoint
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "3.0.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      )
    ];

    for (var preset in defaultPresets) {
      _storage.presetBox.put(preset.id, preset);
    }

    state = state.copyWith(
      presets: defaultPresets,
      activePresetId: defaultPresets.first.id,
    );
  }

  void addPreset(CompilerPreset preset) {
    _storage.presetBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _storage.presetBox.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _storage.presetBox.delete(id);
    state = state.copyWith(
      presets: state.presets.where((p) => p.id != id).toList(),
    );
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void setUseDefaultOneCompiler(bool value) {
    state = state.copyWith(useDefaultOneCompiler: value);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref.read(storageProvider));
});
