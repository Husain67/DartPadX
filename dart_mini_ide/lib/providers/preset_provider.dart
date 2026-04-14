import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import 'file_provider.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, List<CompilerPreset>>((ref) {
  return PresetNotifier(ref.read(storageServiceProvider));
});

class PresetNotifier extends StateNotifier<List<CompilerPreset>> {
  final dynamic storageService;

  PresetNotifier(this.storageService) : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    final presets = storageService.getPresets();
    if (presets.isEmpty) {
      _initDefaultPresets();
    } else {
      state = presets;
    }
  }

  void _initDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        platformName: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "", "files": [{"name": "main.dart", "content": "{code}"}]}',
        responseMapping: ResponseMapping(
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
        )
      ),
      CompilerPreset(
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        responseMapping: ResponseMapping(
          stdoutPath: 'output',
          stderrPath: '',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        )
      ),
      CompilerPreset(
        platformName: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": "{code}"}]}',
        responseMapping: ResponseMapping(
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          executionTimePath: '',
          memoryPath: '',
        )
      ),
      CompilerPreset(
        platformName: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/execute', // Example, not actual public API
        httpMethod: 'POST',
        requestBodyTemplate: '{"language": "dart", "code": "{code}"}',
      ),
      CompilerPreset(
        platformName: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        requestBodyTemplate: '{"code": "{code}", "language": "dart", "input": ""}',
        responseMapping: ResponseMapping(
          stdoutPath: 'output',
          stderrPath: 'error',
        )
      ),
      CompilerPreset(
        platformName: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        requestBodyTemplate: '{"source": "{code}", "lang": "DART", "time_limit": 5, "memory_limit": 262144}',
      ),
      CompilerPreset(
        platformName: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
      ),
    ];

    for (var preset in defaultPresets) {
      storageService.savePreset(preset);
    }
    state = defaultPresets;
  }

  void addPreset(CompilerPreset preset) {
    storageService.savePreset(preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    storageService.savePreset(preset);
    state = state.map((p) => p.id == preset.id ? preset : p).toList();
  }

  void duplicatePreset(CompilerPreset preset) {
    final duplicated = preset.copyWith(
      platformName: '${preset.platformName} (Copy)'
    );
    // Explicitly generate a new ID as instructed by memory
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      platformName: duplicated.platformName,
      endpointUrl: duplicated.endpointUrl,
      httpMethod: duplicated.httpMethod,
      authType: duplicated.authType,
      headers: duplicated.headers,
      queryParams: duplicated.queryParams,
      requestBodyTemplate: duplicated.requestBodyTemplate,
      responseMapping: duplicated.responseMapping,
    );
    storageService.savePreset(newPreset);
    state = [...state, newPreset];
  }

  void deletePreset(String id) {
    storageService.deletePreset(id);
    state = state.where((p) => p.id != id).toList();
  }

  void replaceAll(List<CompilerPreset> presets) {
    storageService.clearPresets();
    for(var preset in presets) {
      storageService.savePreset(preset);
    }
    state = presets;
  }
}
