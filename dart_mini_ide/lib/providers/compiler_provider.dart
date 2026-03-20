import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefault;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefault = true,
  });

  CompilerPreset? get activePreset =>
      presets.where((p) => p.id == activePresetId).firstOrNull;

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefault,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefault: useDefault ?? this.useDefault,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box = Hive.box<CompilerPreset>('presets');
  final Box _prefs = Hive.box('prefs');
  final _uuid = const Uuid();

  CompilerNotifier()
      : super(CompilerState(presets: [], activePresetId: null, useDefault: true)) {
    _loadPresets();
  }

  void _loadPresets() {
    if (_box.isEmpty) {
      _initDefaultPresets();
    }
    final presets = _box.values.toList();
    final activeId = _prefs.get('activePresetId') as String?;
    final useDef = _prefs.get('useDefaultCompiler', defaultValue: true) as bool;

    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefault: useDef,
    );
  }

  void _initDefaultPresets() {
    final presets = [
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'OneCompiler API',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'x-rapidapi-key': 'your_rapidapi_key', 'content-type': 'application/json'},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "index.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'JDoodle API',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        bodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "0", "clientId": "your_client_id", "clientSecret": "your_client_secret"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Piston API',
        endpointUrl: 'https://emacs.emacs.piston.api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Replit API',
        endpointUrl: 'https://replit.com/api/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'CodeX API',
        endpointUrl: 'https://codex.run/api/execute',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'HackerEarth API',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Blank Preset',
        endpointUrl: 'https://',
      ),
    ];

    for (var p in presets) {
      _box.put(p.id, p);
    }
  }

  void toggleUseDefault(bool value) {
    _prefs.put('useDefaultCompiler', value);
    state = state.copyWith(useDefault: value);
  }

  void setActivePreset(String id) {
    _prefs.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    final p = preset.id.isEmpty ? preset.copyWith(id: _uuid.v4()) : preset;
    _box.put(p.id, p);
    state = state.copyWith(presets: [...state.presets, p]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _box.delete(id);
    final presets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(
      presets: presets,
      activePresetId: state.activePresetId == id ? null : state.activePresetId,
    );
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      platformName: '${preset.platformName} (Copy)',
    );
    addPreset(newPreset);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
