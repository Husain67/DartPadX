import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/compiler_preset.dart';
import '../data/hive_repository.dart';
import '../data/shared_prefs_repository.dart';
import 'file_provider.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier(ref.watch(hiveRepoProvider), ref.watch(sharedPrefsProvider));
});

class PresetState {
  final List<CompilerPreset> presets;
  final String? selectedPresetId;
  final bool useDefaultOneCompiler;

  PresetState({
    this.presets = const [],
    this.selectedPresetId,
    this.useDefaultOneCompiler = true,
  });

  CompilerPreset? get selectedPreset {
    if (selectedPresetId == null || presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return null;
    }
  }

  PresetState copyWith({
    List<CompilerPreset>? presets,
    String? selectedPresetId,
    bool? useDefaultOneCompiler,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  final HiveRepository _hiveRepo;
  final SharedPrefsRepository _prefsRepo;

  PresetNotifier(this._hiveRepo, this._prefsRepo) : super(PresetState()) {
    _loadPresets();
  }

  void _loadPresets() {
    List<CompilerPreset> loadedPresets = _hiveRepo.getPresets();

    // Add default presets if empty
    if (loadedPresets.isEmpty) {
      final oneCompiler = CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'x-rapidapi-key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          'Content-Type': 'application/json'
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
      );

      final jdoodle = CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory'
      );

      final piston = CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"content": "{code}"}]}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: ''
      );

      final replit = CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit (Beta)',
        endpointUrl: 'https://replit.com/api/v1/repls/...',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{}',
        stdoutPath: 'out',
        stderrPath: 'err',
      );

      final codex = CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        errorPath: 'error'
      );

      final hackerearth = CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        requestBodyTemplate: '{"source": "{code}", "lang": "DART"}',
        stdoutPath: 'result.run_status.output',
      );

      final blank = CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank Preset',
        endpointUrl: 'https://...',
        httpMethod: 'POST',
      );

      _hiveRepo.savePreset(oneCompiler);
      _hiveRepo.savePreset(jdoodle);
      _hiveRepo.savePreset(piston);
      _hiveRepo.savePreset(replit);
      _hiveRepo.savePreset(codex);
      _hiveRepo.savePreset(hackerearth);
      _hiveRepo.savePreset(blank);

      loadedPresets = [oneCompiler, jdoodle, piston, replit, codex, hackerearth, blank];
    }

    String? savedCurrentId = _prefsRepo.getCurrentPresetId();
    bool useDefault = _prefsRepo.getUseDefaultOneCompiler();

    if (savedCurrentId == null && loadedPresets.isNotEmpty) {
      savedCurrentId = loadedPresets.first.id;
      _prefsRepo.setCurrentPresetId(savedCurrentId);
    }

    state = PresetState(
      presets: loadedPresets,
      selectedPresetId: savedCurrentId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void addPreset(CompilerPreset preset) {
    _hiveRepo.savePreset(preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _hiveRepo.savePreset(preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _hiveRepo.deletePreset(id);
    final remaining = state.presets.where((p) => p.id != id).toList();

    String? nextId = state.selectedPresetId;
    if (nextId == id) {
      nextId = remaining.isNotEmpty ? remaining.first.id : null;
      if (nextId != null) {
        _prefsRepo.setCurrentPresetId(nextId);
      }
    }

    state = state.copyWith(presets: remaining, selectedPresetId: nextId);
  }

  void selectPreset(String id) {
    _prefsRepo.setCurrentPresetId(id);
    state = state.copyWith(selectedPresetId: id);
  }

  void toggleUseDefault(bool useDefault) {
    _prefsRepo.setUseDefaultOneCompiler(useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void importPresets(List<CompilerPreset> newPresets) {
    for (var preset in newPresets) {
      // Ensure unique IDs when importing
      final newPreset = CompilerPreset(
        id: const Uuid().v4(),
        name: preset.name,
        endpointUrl: preset.endpointUrl,
        httpMethod: preset.httpMethod,
        authType: preset.authType,
        headers: preset.headers,
        queryParams: preset.queryParams,
        requestBodyTemplate: preset.requestBodyTemplate,
        stdoutPath: preset.stdoutPath,
        stderrPath: preset.stderrPath,
        errorPath: preset.errorPath,
        executionTimePath: preset.executionTimePath,
        memoryPath: preset.memoryPath,
      );
      _hiveRepo.savePreset(newPreset);
      state = state.copyWith(presets: [...state.presets, newPreset]);
    }
  }
}
