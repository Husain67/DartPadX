import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

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
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: []));

  Box<CompilerPreset>? _box;
  Box? _settingsBox;

  CompilerState get currentState => state;

  Future<void> init() async {
    _box = Hive.box<CompilerPreset>('presetsBox');
    _settingsBox = Hive.box('settingsBox');

    List<CompilerPreset> initialPresets = _box!.values.toList();

    if (initialPresets.isEmpty) {
      initialPresets = _getPreloadedPresets();
      for (var p in initialPresets) {
        _box!.put(p.id, p);
      }
    }

    bool useDefault = _settingsBox!.get('useDefaultOneCompiler', defaultValue: true);
    String? activeId = _settingsBox!.get('activePresetId');
    if (activeId == null && initialPresets.isNotEmpty) {
      activeId = initialPresets.first.id;
    }

    state = state.copyWith(
      presets: initialPresets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void setUseDefaultOneCompiler(bool value) {
    _settingsBox?.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _settingsBox?.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addOrUpdatePreset(CompilerPreset preset) {
    _box?.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    List<CompilerPreset> updated;
    if (index >= 0) {
      updated = List.from(state.presets)..[index] = preset;
    } else {
      updated = [...state.presets, preset];
    }
    state = state.copyWith(presets: updated);
  }

  void deletePreset(String id) {
    _box?.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id && remaining.isNotEmpty) {
      newActiveId = remaining.first.id;
      _settingsBox?.put('activePresetId', newActiveId);
    }
    state = state.copyWith(presets: remaining, activePresetId: newActiveId);
  }

  List<CompilerPreset> _getPreloadedPresets() {
    return [
      CompilerPreset(
        id: 'preset_onecompiler',
        name: 'OneCompiler API (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'x-rapidapi-key': 'YOUR_RAPIDAPI_KEY',
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
      ),
      CompilerPreset(
        id: 'preset_jdoodle',
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "4", "stdin": "{stdin}", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
        stdoutPath: 'output',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'preset_piston',
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"language": "dart", "version": "2.19.6", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: 'preset_replit',
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/...',
      ),
      CompilerPreset(
        id: 'preset_codex',
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
      ),
      CompilerPreset(
        id: 'preset_hackerearth',
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      ),
      CompilerPreset(
        id: 'preset_blank',
        name: 'Blank',
        endpointUrl: '',
      ),
    ];
  }
}
