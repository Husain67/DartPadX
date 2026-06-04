import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final bool useDefaultOneCompiler;
  final String? activePresetId;

  CompilerState({
    required this.presets,
    required this.useDefaultOneCompiler,
    this.activePresetId,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefaultOneCompiler,
    String? activePresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  CompilerPreset? get activePreset => activePresetId == null
      ? null
      : presets.where((p) => p.id == activePresetId).firstOrNull;
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
        name: 'OneCompiler API (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: [
          HeaderModel(key: 'X-RapidAPI-Key', value: '{authValue}'),
          HeaderModel(key: 'Content-Type', value: 'application/json'),
        ],
        queryParams: [],
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'exception',
        responseTimePath: 'executionTime',
        responseMemoryPath: '',
        isDefault: false,
      ),
       CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: [
          HeaderModel(key: 'Content-Type', value: 'application/json'),
        ],
        queryParams: [],
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        responseStdoutPath: 'output',
        responseStderrPath: '',
        responseErrorPath: 'error',
        responseTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
        isDefault: false,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: [
          HeaderModel(key: 'Content-Type', value: 'application/json'),
        ],
        queryParams: [],
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        responseErrorPath: 'message',
        responseTimePath: '',
        responseMemoryPath: '',
        isDefault: false,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: [
          HeaderModel(key: 'Content-Type', value: 'application/json'),
        ],
        queryParams: [],
        requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: '',
        responseTimePath: '',
        responseMemoryPath: '',
        isDefault: false,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: [],
        queryParams: [],
        requestBodyTemplate: '{}',
        responseStdoutPath: '',
        responseStderrPath: '',
        responseErrorPath: '',
        responseTimePath: '',
        responseMemoryPath: '',
        isDefault: false,
      ),
    ];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }

    state = state.copyWith(presets: _box.values.toList());
  }

  void toggleUseDefaultOneCompiler(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(presets: updatedPresets);
    if (state.activePresetId == id) {
      final newActiveId = updatedPresets.isNotEmpty ? updatedPresets.first.id : null;
      if (newActiveId != null) {
        setActivePreset(newActiveId);
      } else {
        _prefs.remove('activePresetId');
        state = state.copyWith(activePresetId: null);
      }
    }
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden');
});

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('compiler_presets');
  final prefs = ref.watch(sharedPrefsProvider);
  return CompilerNotifier(box, prefs);
});
