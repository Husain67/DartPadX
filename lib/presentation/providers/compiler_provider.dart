import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/compiler_preset.dart';
import '../../data/repositories/local_storage.dart';
import '../../core/constants/app_constants.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId; // null means default OneCompiler

  CompilerState({required this.presets, this.activePresetId});

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId, bool clearActivePreset = false}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: clearActivePreset ? null : (activePresetId ?? this.activePresetId),
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Uuid _uuid = const Uuid();

  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    List<CompilerPreset> boxPresets = LocalStorage.presetsBox.values.toList();
    if (boxPresets.isEmpty) {
      // Create Pre-loaded Defaults
      boxPresets = _createPreloadedPresets();
      for (var p in boxPresets) {
        LocalStorage.presetsBox.put(p.id, p);
      }
    }

    final activeId = LocalStorage.prefs.getString(AppConstants.activePresetIdKey);
    state = state.copyWith(presets: boxPresets, activePresetId: activeId);
  }

  List<CompilerPreset> _createPreloadedPresets() {
    return [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston API',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        timePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle (Example)',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        timePath: 'cpuTime',
        memoryPath: 'memory',
      ),
            CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit (Example)',
        endpointUrl: 'https://replit.com/api/v0/repls/execute',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        authValue: 'YOUR_REPLIT_TOKEN',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}"\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        timePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX API',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        timePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth (Example)',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'YOUR_CLIENT_SECRET',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "lang": "DART",\n  "source": "{code}",\n  "input": "{stdin}",\n  "memory_limit": 262144,\n  "time_limit": 5\n}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        timePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank Template',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        timePath: '',
        memoryPath: '',
      )
    ];
  }

  void setActivePreset(String? id) {
    if (id == null) {
      LocalStorage.prefs.remove(AppConstants.activePresetIdKey);
      state = state.copyWith(clearActivePreset: true);
    } else {
      LocalStorage.prefs.setString(AppConstants.activePresetIdKey, id);
      state = state.copyWith(activePresetId: id);
    }
  }

  void addPreset(CompilerPreset preset) {
    LocalStorage.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    LocalStorage.presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newList = List<CompilerPreset>.from(state.presets);
      newList[index] = preset;
      state = state.copyWith(presets: newList);
    }
  }

  void deletePreset(String id) {
    LocalStorage.presetsBox.delete(id);
    if (state.activePresetId == id) {
      setActivePreset(null);
    }
    state = state.copyWith(presets: state.presets.where((p) => p.id != id).toList());
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
