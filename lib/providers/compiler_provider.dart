import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

final builtInPresets = [
  CompilerPreset(
    id: 'onecompiler',
    name: 'OneCompiler',
    url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
    method: 'POST',
    authType: 'API-Key Header',
    authValue: const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: ''),
    headers: {
      'Content-Type': 'application/json',
      'X-RapidAPI-Key': '{authValue}',
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    },
    bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
    stdoutPath: 'stdout',
    stderrPath: 'stderr',
    errorPath: 'exception',
    executionTimePath: 'executionTime',
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'jdoodle',
    name: 'JDoodle',
    url: 'https://api.jdoodle.com/v1/execute',
    method: 'POST',
    bodyTemplate: '{"clientId": "{clientId}", "clientSecret": "{clientSecret}", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "4"}',
    stdoutPath: 'output',
    memoryPath: 'memory',
    executionTimePath: 'cpuTime',
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'piston',
    name: 'Piston',
    url: 'https://emacs.piston.rs/api/v2/execute',
    method: 'POST',
    bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
    stdoutPath: 'run.stdout',
    stderrPath: 'run.stderr',
    errorPath: 'run.output', // combined fallback
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'replit',
    name: 'Replit',
    url: 'https://replit.com/api/v1/run', // Mock endpoint for structure
    method: 'POST',
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'codex',
    name: 'CodeX',
    url: 'https://api.codex.jaagrav.in',
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
    stdoutPath: 'output',
    errorPath: 'error',
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'hackerearth',
    name: 'HackerEarth',
    url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
    method: 'POST',
    isBuiltIn: true,
  ),
  CompilerPreset(
    id: 'blank',
    name: 'Blank',
    url: 'https://',
    method: 'POST',
    isBuiltIn: true,
  )
];

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    this.presets = const [],
    this.activePresetId = 'onecompiler',
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

  CompilerPreset get activePreset {
    return presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;
  final SharedPreferences _prefs;

  CompilerNotifier(this._box, this._prefs) : super(CompilerState()) {
    _loadPresets();
  }

  CompilerState get currentState => state;

  void _loadPresets() {
    bool useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    String activeId = _prefs.getString('activePresetId') ?? 'onecompiler';

    if (_box.isEmpty) {
      for (var p in builtInPresets) {
        _box.put(p.id, p);
      }
    }

    final presets = _box.values.toList();
    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void addPreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(id: const Uuid().v4(), isBuiltIn: false);
    _box.put(newPreset.id, newPreset);
    state = state.copyWith(presets: [...state.presets, newPreset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    final preset = _box.get(id);
    if (preset != null && preset.isBuiltIn) return;

    _box.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    String newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = 'onecompiler';
      _prefs.setString('activePresetId', newActiveId);
    }
    state = state.copyWith(presets: remaining, activePresetId: newActiveId);
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

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  return Hive.box<CompilerPreset>('compiler_presets');
});

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref.watch(compilerBoxProvider), ref.watch(sharedPrefsProvider));
});
