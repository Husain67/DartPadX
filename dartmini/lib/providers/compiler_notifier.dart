import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

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
  final Box<CompilerPreset> _box;
  final SharedPreferences _prefs;

  CompilerNotifier(this._box, this._prefs)
      : super(CompilerState(
          presets: _box.values.toList(),
          useDefaultOneCompiler: _prefs.getBool('useDefaultOneCompiler') ?? true,
          activePresetId: _prefs.getString('activePresetId'),
        )) {
    if (state.presets.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-RapidAPI-Key': '',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseMapping: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': '',
        },
      ),

      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "script": "{code}",\n  "language": "dart",\n  "versionIndex": "0",\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET"\n}',
        responseMapping: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'statusCode',
          'executionTime': 'cpuTime',
          'memory': 'memory'
        },
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        responseMapping: {
          'stdout': 'run.stdout',
          'stderr': 'run.stderr',
          'error': 'message',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}"\n}',
        responseMapping: {'stdout': '', 'stderr': '', 'error': '', 'executionTime': '', 'memory': ''},
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
        responseMapping: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'error',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{\n  "lang": "DART",\n  "source": "{code}",\n  "input": "{stdin}",\n  "memory_limit": 262144,\n  "time_limit": 5\n}',
        responseMapping: {
          'stdout': 'result.run_status.output',
          'stderr': 'result.run_status.stderr',
          'error': 'message',
          'executionTime': 'result.run_status.time_used',
          'memory': 'result.run_status.memory_used'
        },
      ),

      // Add a Blank one
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}"\n}',
        responseMapping: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'message',
          'executionTime': '',
          'memory': '',
        },
      ),
    ];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }

    state = state.copyWith(presets: _box.values.toList());
  }

  void toggleDefault(bool useDefault) {
    _prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.copyWith(presets: _box.values.toList());
    if (state.activePresetId == id) {
      _prefs.remove('activePresetId');
      state = state.copyWith(activePresetId: null);
    }
  }
}

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) => throw UnimplementedError());
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = ref.watch(compilerBoxProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  return CompilerNotifier(box, prefs);
});
