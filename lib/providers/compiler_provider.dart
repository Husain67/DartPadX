import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  CompilerState({required this.presets, required this.activePresetId});

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  CompilerPreset get activePreset => presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [], activePresetId: '')) {
    _initPresets();
  }

  void _initPresets() {
    List<CompilerPreset> loaded = HiveService.getPresets();

    // Explicit predefined required presets
    if (loaded.isEmpty) {
      final systemPresets = [
        CompilerPreset(
          id: 'oc_default',
          name: 'OneCompiler (Default)',
          endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          method: 'POST',
          authType: 'API-Key Header',
          headers: [
            {'key': 'x-rapidapi-key', 'value': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'},
            {'key': 'x-rapidapi-host', 'value': 'onecompiler-apis.p.rapidapi.com'},
            {'key': 'Content-Type', 'value': 'application/json'}
          ],
          queryParams: [],
          bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
          isSystem: true,
          isDefault: true,
        ),
        CompilerPreset(
          id: 'piston_default',
          name: 'Piston',
          endpoint: 'https://emkc.org/api/v2/piston/execute',
          method: 'POST',
          authType: 'None',
          headers: [{'key': 'Content-Type', 'value': 'application/json'}],
          queryParams: [],
          bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          executionTimePath: '',
          memoryPath: '',
          isSystem: true,
        ),
        CompilerPreset(
          id: 'jdoodle_default',
          name: 'JDoodle',
          endpoint: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          authType: 'None',
          headers: [{'key': 'Content-Type', 'value': 'application/json'}],
          queryParams: [],
          bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: '',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
          isSystem: true,
        ),
        CompilerPreset(
          id: 'replit_default',
          name: 'Replit',
          endpoint: 'https://replit.com/api/v1/run',
          method: 'POST',
          authType: 'Bearer Token',
          headers: [{'key': 'Content-Type', 'value': 'application/json'}],
          queryParams: [],
          bodyTemplate: '{"language": "dart", "code": "{code}", "stdin": "{stdin}"}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'error',
          executionTimePath: '',
          memoryPath: '',
          isSystem: true,
        ),
        CompilerPreset(
          id: 'codex_default',
          name: 'CodeX',
          endpoint: 'https://api.codex.jaagrav.in',
          method: 'POST',
          authType: 'None',
          headers: [{'key': 'Content-Type', 'value': 'application/json'}],
          queryParams: [],
          bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isSystem: true,
        ),
        CompilerPreset(
          id: 'hackerearth_default',
          name: 'HackerEarth',
          endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          method: 'POST',
          authType: 'API-Key Header',
          headers: [
            {'key': 'client-secret', 'value': 'YOUR_API_KEY'},
            {'key': 'Content-Type', 'value': 'application/json'}
          ],
          queryParams: [],
          bodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}", "memory_limit": 262144, "time_limit": 5}',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          errorPath: 'result.compile_status',
          executionTimePath: 'result.run_status.time_used',
          memoryPath: 'result.run_status.memory_used',
          isSystem: true,
        ),
        CompilerPreset(
          id: 'blank_default',
          name: 'Blank',
          endpoint: 'https://your-api.com/execute',
          method: 'POST',
          authType: 'None',
          headers: [],
          queryParams: [],
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isSystem: true,
        ),
      ];

      for (var p in systemPresets) {
        HiveService.savePreset(p);
      }
      loaded = systemPresets;
    }

    // Default to one compiler if no active is set in hive
    String activeId = loaded.firstWhere((p) => p.isDefault, orElse: () => loaded.first).id;
    state = CompilerState(presets: loaded, activePresetId: activeId);
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
    final updatedPresets = state.presets.map((p) => p.copyWith(isDefault: p.id == id)).toList();
    state = state.copyWith(presets: updatedPresets);
    for (var p in updatedPresets) {
      HiveService.savePreset(p);
    }
  }

  void addPreset(CompilerPreset preset) {
    HiveService.savePreset(preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    HiveService.savePreset(preset);
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updated);
  }

  void deletePreset(String id) {
    HiveService.deletePreset(id);
    final updated = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: updated);
    if (state.activePresetId == id && updated.isNotEmpty) {
      setActivePreset(updated.first.id);
    }
  }

  void duplicatePreset(String id) {
    final original = state.presets.firstWhere((p) => p.id == id);
    final copy = original.copyWith(
      id: const Uuid().v4(),
      name: '${original.name} (Copy)',
      isSystem: false,
      isDefault: false,
    );
    addPreset(copy);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
