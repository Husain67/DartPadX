import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    this.presets = const [],
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

  CompilerPreset? get activePreset =>
      presets.cast<CompilerPreset?>().firstWhere((p) => p?.id == activePresetId, orElse: () => null);
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState()) {
    _loadPresets();
  }

  late Box<CompilerPreset> _box;
  final _uuid = const Uuid();
  late SharedPreferences _prefs;

  CompilerState get currentState => state;

  Future<void> _loadPresets() async {
    _box = Hive.box<CompilerPreset>('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    if (_box.isEmpty) {
      _seedDefaultPresets();
    }

    final presets = _box.values.toList();

    // Ensure active ID exists
    String? finalActiveId = activeId;
    if (finalActiveId == null || !presets.any((p) => p.id == finalActiveId)) {
        finalActiveId = presets.isNotEmpty ? presets.first.id : null;
        if(finalActiveId != null) {
          _prefs.setString('activePresetId', finalActiveId);
        }
    }

    state = state.copyWith(
      presets: presets,
      useDefaultOneCompiler: useDefault,
      activePresetId: finalActiveId,
    );
  }

  void _seedDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: 'default_onecompiler',
        platformName: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'x-rapidapi-key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'exception',
        responseTimePath: 'executionTime',
        responseMemoryPath: '',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'default_jdoodle',
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "4"\n}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: 'error',
        responseTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'default_piston',
        platformName: 'Piston',
        endpointUrl: 'https://emacs.ch/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        responseErrorPath: 'run.error',
        responseTimePath: '',
        responseMemoryPath: '',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: 'default_blank',
        platformName: 'Blank Custom API',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        requestBodyTemplate: '{\n  "code": "{code}"\n}',
        responseStdoutPath: 'result',
        responseStderrPath: 'error',
        responseErrorPath: '',
        responseTimePath: '',
        responseMemoryPath: '',
        isReadOnly: false,
      ),
    ];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    if (preset.isReadOnly) return;
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    if (preset.isReadOnly) return;
    _box.delete(id);

    String? activeId = state.activePresetId;
    if (activeId == id) {
        final remaining = _box.values.toList();
        activeId = remaining.isNotEmpty ? remaining.first.id : null;
        if (activeId != null) {
            _prefs.setString('activePresetId', activeId);
        } else {
             _prefs.remove('activePresetId');
        }
    }

    state = state.copyWith(
        presets: _box.values.toList(),
        activePresetId: activeId,
    );
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      platformName: '${preset.platformName} (Copy)',
      isReadOnly: false,
    );
    addPreset(newPreset);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void toggleUseDefault(bool useDefault) {
    _prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }
}
