import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../main.dart'; // for sharedPreferencesProvider

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('presets');
  final prefs = ref.read(sharedPreferencesProvider);
  return CompilerNotifier(box, prefs);
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
  final Box<CompilerPreset> _box;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  CompilerNotifier(this._box, this._prefs) : super(CompilerState(presets: [])) {
    _init();
  }

  void _init() {
    _ensurePreloadedPresets();
    final presets = _box.values.toList();

    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    state = CompilerState(
      presets: presets,
      activePresetId: activeId ?? (presets.isNotEmpty ? presets.first.id : null),
      useDefaultOneCompiler: useDefault,
    );
  }

  void _ensurePreloadedPresets() {
    if (_box.isEmpty) {
      final preloaded = [
        CompilerPreset(
          id: 'onecompiler_default',
          name: 'OneCompiler',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          headers: [
            {'key': 'X-RapidAPI-Key', 'value': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'},
            {'key': 'X-RapidAPI-Host', 'value': 'onecompiler-apis.p.rapidapi.com'},
            {'key': 'Content-Type', 'value': 'application/json'},
          ],
          queryParams: [],
          bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
          isPreloaded: true,
        ),
        CompilerPreset(
          id: 'jdoodle_default',
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: [
            {'key': 'Content-Type', 'value': 'application/json'},
          ],
          queryParams: [],
          bodyTemplate: '{\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "4",\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET"\n}',
          stdoutPath: 'output',
          stderrPath: '', // JDoodle combines them sometimes
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
          isPreloaded: true,
        ),
        CompilerPreset(
          id: 'piston_default',
          name: 'Piston',
          endpointUrl: 'https://emkc.org/api/v2/piston/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: [
            {'key': 'Content-Type', 'value': 'application/json'},
          ],
          queryParams: [],
          bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'message',
          executionTimePath: '',
          memoryPath: '',
          isPreloaded: true,
        ),
        // Add Replit, CodeX, HackerEarth and Blank stubs
        CompilerPreset(
          id: 'blank_default',
          name: 'Blank',
          endpointUrl: '',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          headers: [],
          queryParams: [],
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          executionTimePath: '',
          memoryPath: '',
          isPreloaded: true,
        )
      ];

      for (var p in preloaded) {
        _box.put(p.id, p);
      }
    }
  }

  void setUseDefaultOneCompiler(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }

  void addPreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(id: _uuid.v4(), isPreloaded: false);
    _box.put(newPreset.id, newPreset);
    state = state.copyWith(presets: [...state.presets, newPreset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final updatedPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = updatedPresets.isNotEmpty ? updatedPresets.first.id : null;
      if (newActiveId != null) {
        _prefs.setString('activePresetId', newActiveId);
      } else {
        _prefs.remove('activePresetId');
      }
    }
    state = state.copyWith(presets: updatedPresets, activePresetId: newActiveId);
  }
}
