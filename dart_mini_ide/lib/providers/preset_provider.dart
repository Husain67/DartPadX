import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../services/storage_service.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPreset> presets;
  final CompilerPreset? activePreset;

  PresetState({required this.presets, this.activePreset});
}

class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier() : super(PresetState(presets: [])) {
    _loadPresets();
  }

  final _uuid = const Uuid();
  final _box = StorageService.presetsBox;

  void _loadPresets() {
    final presets = _box.values.toList();
    CompilerPreset? defaultPreset;
    if (presets.isEmpty) {
      final oneCompilerKey = const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac');

      final preloadedPresets = [
        CompilerPreset(
          id: _uuid.v4(),
          name: 'OneCompiler',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authValue: 'X-RapidAPI-Key: $oneCompilerKey',
          headers: {'Content-Type': 'application/json', 'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'},
          queryParams: {},
          requestBodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: 'limitRemaining',
          isDefault: true,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'Piston (Engine)',
          endpointUrl: 'https://emkc.org/api/v2/piston/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"language": "{language}", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"script": "{code}", "language": "{language}", "versionIndex": "0", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
          isDefault: false,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'CodeX',
          endpointUrl: 'https://api.codex.jaagrav.in',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          queryParams: {},
          requestBodyTemplate: 'code={code}&language={language}&input={stdin}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'Replit API (Mock)',
          endpointUrl: 'https://replit.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'Bearer Token',
          authValue: 'YOUR_REPLIT_TOKEN',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"code": "{code}", "language": "{language}"}',
          stdoutPath: 'result.stdout',
          stderrPath: 'result.stderr',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'HackerEarth API (Mock)',
          endpointUrl: 'https://api.hackerearth.com/v3/code/run/',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authValue: 'client-secret: YOUR_SECRET',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"source": "{code}", "lang": "{language}", "time_limit": 5, "memory_limit": 262144}',
          stdoutPath: 'run_status.output',
          stderrPath: 'run_status.stderr',
          errorPath: 'compile_status',
          executionTimePath: 'run_status.time_used',
          memoryPath: 'run_status.memory_used',
          isDefault: false,
        ),
        CompilerPreset(
          id: _uuid.v4(),
          name: 'Blank',
          endpointUrl: 'https://example.com/api',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          requestBodyTemplate: '{"code": "{code}", "language": "{language}"}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
          isDefault: false,
        )
      ];

      for (var p in preloadedPresets) {
        _box.put(p.id, p);
        presets.add(p);
      }
      defaultPreset = preloadedPresets.first;
    } else {
      defaultPreset = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
    }
    state = PresetState(presets: presets, activePreset: defaultPreset);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = PresetState(presets: [...state.presets, preset], activePreset: state.activePreset);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = PresetState(presets: updatedPresets, activePreset: state.activePreset?.id == preset.id ? preset : state.activePreset);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    CompilerPreset? newActive = state.activePreset;
    if (newActive?.id == id) {
      newActive = updatedPresets.isNotEmpty ? updatedPresets.first : null;
    }
    state = PresetState(presets: updatedPresets, activePreset: newActive);
  }

  void setActivePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    // Update default status
    for (var p in state.presets) {
      p.isDefault = (p.id == id);
      p.save();
    }
    state = PresetState(presets: state.presets, activePreset: preset);
  }
}
