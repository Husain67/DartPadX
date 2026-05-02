import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  CompilerState({required this.presets, required this.activePresetId});

  CompilerPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  CompilerNotifier(this._box) : super(CompilerState(presets: [], activePresetId: '')) {
    _init();
  }

  void _init() {
    final storedPresets = _box.values.toList();
    if (storedPresets.isEmpty) {
      final defaultPresets = _getDefaultPresets();
      for (var preset in defaultPresets) {
        _box.put(preset.id, preset);
      }
      state = CompilerState(presets: defaultPresets, activePresetId: defaultPresets.first.id);
    } else {
      state = CompilerState(presets: storedPresets, activePresetId: storedPresets.first.id);
    }
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
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
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        responseMapping: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': ''
        },
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
        responseMapping: {
          'stdout': 'output',
          'stderr': '',
          'error': 'error',
          'executionTime': 'cpuTime',
          'memory': 'memory'
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        responseMapping: {
          'stdout': 'run.stdout',
          'stderr': 'run.stderr',
          'error': 'compile.stderr',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        responseMapping: {
          'stdout': '',
          'stderr': '',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
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
        bodyTemplate: 'code={code}&language=cpp&input={stdin}',
        responseMapping: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'error',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: '',
        headers: {
          'Content-Type': 'application/json',
          'client-secret': '{authValue}'
        },
        queryParams: {},
        bodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        responseMapping: {
          'stdout': 'result.run_status.output',
          'stderr': 'result.run_status.stderr',
          'error': 'result.compile_status',
          'executionTime': 'result.run_status.time_used',
          'memory': 'result.run_status.memory_used'
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        responseMapping: {
          'stdout': '',
          'stderr': '',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
      ),
    ];
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset], activePresetId: preset.id);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final presets = List<CompilerPreset>.from(state.presets);
    final index = presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      presets[index] = preset;
      state = state.copyWith(presets: presets);
    }
  }

  void deletePreset(String id) {
    _box.delete(id);
    final presets = state.presets.where((p) => p.id != id).toList();
    String newActiveId = state.activePresetId;
    if (state.activePresetId == id && presets.isNotEmpty) {
      newActiveId = presets.first.id;
    }
    state = CompilerState(presets: presets, activePresetId: newActiveId);
  }
}

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  throw UnimplementedError('compilerBoxProvider must be overridden');
});

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = ref.watch(compilerBoxProvider);
  return CompilerNotifier(box);
});
