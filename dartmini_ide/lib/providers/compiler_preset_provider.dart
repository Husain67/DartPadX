import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

class CompilerPresetNotifier extends StateNotifier<List<CompilerPreset>> {
  CompilerPresetNotifier() : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    if (box.values.isEmpty) {
      // Add defaults
      final defaults = [
        CompilerPreset(
          name: 'OneCompiler',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authKey: 'X-RapidAPI-Key',
          authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          headers: {'Content-Type': 'application/json'},
          requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
        ),
        CompilerPreset(
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          requestBodyTemplate: '{"clientId": "CLIENT_ID", "clientSecret": "CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
           name: 'Piston',
           endpointUrl: 'https://emacsx.com/api/v2/execute',
           httpMethod: 'POST',
           requestBodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
           stdoutPath: 'run.stdout',
           stderrPath: 'run.stderr',
           errorPath: 'compile.stderr'
        ),
        CompilerPreset(name: 'Replit', endpointUrl: 'https://replit.com/api/v1/run'),
        CompilerPreset(name: 'CodeX', endpointUrl: 'https://api.codex.jaagrav.in'),
        CompilerPreset(name: 'HackerEarth', endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/'),
        CompilerPreset(name: 'Blank', endpointUrl: ''),
      ];
      for (var p in defaults) {
        box.put(p.id, p);
      }
    }
    state = box.values.toList();
  }

  void addPreset(CompilerPreset preset) {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    box.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    box.put(preset.id, preset);
    state = [
      for (final p in state)
        if (p.id == preset.id) preset else p,
    ];
  }

  void deletePreset(String id) {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }
}

final compilerPresetProvider = StateNotifierProvider<CompilerPresetNotifier, List<CompilerPreset>>((ref) {
  return CompilerPresetNotifier();
});
