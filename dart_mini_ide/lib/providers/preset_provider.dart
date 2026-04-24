import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class PresetNotifier extends StateNotifier<List<CompilerPreset>> {
  final Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  PresetNotifier(this._box) : super(_box.values.toList()) {
    if (state.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
    final presets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': '{authValue}',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
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
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "4"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emacs.emacsconf.org/piston/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "version": "*", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'run.error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
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

    for (var preset in presets) {
      _box.put(preset.id, preset);
    }
    state = presets;
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      name: '${preset.name} (Copy)',
    );
    savePreset(newPreset);
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }

  void importPresetsFromJson(List<CompilerPreset> newPresets) {
    for (var preset in newPresets) {
      _box.put(preset.id, preset);
    }
    state = _box.values.toList();
  }
}

final presetBoxProvider = Provider<Box<CompilerPreset>>((ref) => throw UnimplementedError());

final presetProvider = StateNotifierProvider<PresetNotifier, List<CompilerPreset>>((ref) {
  final box = ref.watch(presetBoxProvider);
  return PresetNotifier(box);
});

final selectedPresetIdProvider = StateProvider<String?>((ref) => null);

final selectedPresetProvider = Provider<CompilerPreset?>((ref) {
  final presets = ref.watch(presetProvider);
  final selectedId = ref.watch(selectedPresetIdProvider);

  if (selectedId == null && presets.isNotEmpty) {
    return presets.first;
  }

  try {
    return presets.firstWhere((p) => p.id == selectedId);
  } catch (_) {
    return presets.isNotEmpty ? presets.first : null;
  }
});
