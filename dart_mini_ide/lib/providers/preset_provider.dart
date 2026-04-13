import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class PresetState {
  final List<CompilerPreset> presets;

  PresetState({required this.presets});
}

class PresetNotifier extends StateNotifier<PresetState> {
  final Box<CompilerPreset> presetBox;

  PresetNotifier(this.presetBox) : super(PresetState(presets: presetBox.values.toList())) {
    if (state.presets.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
    final defaults = [
            CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"name": "main.dart", "content": {code}}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpoint: 'https://api.replit.com/v1/execute',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'Authorization',
        authValue: 'Bearer YOUR_REPLIT_TOKEN',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "code": {code}}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        bodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'client-secret',
        authValue: 'YOUR_CLIENT_SECRET',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"lang": "DART", "source": {code}, "input": "{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: 'const String.fromEnvironment(\'RAPID_API_KEY\')', // Replaced in execution provider
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": {code}, "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpoint: 'https://api.example.com/execute',
        method: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];

    for (var preset in defaults) {
      presetBox.put(preset.id, preset);
    }
    state = PresetState(presets: presetBox.values.toList());
  }

  void addPreset(CompilerPreset preset) {
    presetBox.put(preset.id, preset);
    state = PresetState(presets: presetBox.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    presetBox.put(preset.id, preset);
    state = PresetState(presets: presetBox.values.toList());
  }

  void deletePreset(String id) {
    presetBox.delete(id);
    state = PresetState(presets: presetBox.values.toList());
    if (state.presets.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newId = const Uuid().v4();
    final newPreset = CompilerPreset(
      id: newId,
      name: '${preset.name} (Copy)',
      endpoint: preset.endpoint,
      method: preset.method,
      authType: preset.authType,
      authKey: preset.authKey,
      authValue: preset.authValue,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      bodyTemplate: preset.bodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      executionTimePath: preset.executionTimePath,
      memoryPath: preset.memoryPath,
    );
    addPreset(newPreset);
  }
}

final presetBoxProvider = Provider<Box<CompilerPreset>>((ref) => throw UnimplementedError());

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  final box = ref.watch(presetBoxProvider);
  return PresetNotifier(box);
});
