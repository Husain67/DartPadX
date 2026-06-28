import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useOneCompiler = true,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _presetBox = Hive.box<CompilerPreset>('presets');
  final SharedPreferences _prefs;

  CompilerNotifier(this._prefs) : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  CompilerState get currentState => state;

  void _loadPresets() {
    final presets = _presetBox.values.toList();
    final useOne = _prefs.getBool('useOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');


    if (presets.isEmpty) {
      // Add a default preset as an example for users
      final myCustom = CompilerPreset(
        name: 'My Custom API',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        stdoutPath: 'data.output',
        stderrPath: 'data.error',
      );

      final piston = CompilerPreset(
        name: 'Piston (Emulated)',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '''{
  "language": "{language}",
  "version": "*",
  "files": [{"content": "{code}"}],
  "stdin": "{stdin}"
}''',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
      );

      final jdoodle = CompilerPreset(
        name: 'JDoodle (Requires Client ID/Secret in body)',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '''{
  "script": "{code}",
  "language": "dart",
  "versionIndex": "0",
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET"
}''',
        stdoutPath: 'output',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      );

      final codex = CompilerPreset(
        name: 'CodeX API',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        errorPath: 'error',
      );

      for (var p in [myCustom, piston, jdoodle, codex]) {
         _presetBox.put(p.id, p);
         presets.add(p);
      }
    }


    state = state.copyWith(
      presets: presets,
      useOneCompiler: useOne,
      activePresetId: presets.any((p) => p.id == activeId) ? activeId : presets.first.id,
    );
  }

  void toggleUseOneCompiler(bool value) {
    _prefs.setBool('useOneCompiler', value);
    state = state.copyWith(useOneCompiler: value);
  }

  void setActivePreset(String id) {
    if (state.presets.any((p) => p.id == id)) {
      _prefs.setString('activePresetId', id);
      state = state.copyWith(activePresetId: id);

      // Update all presets to reflect current default
      for (var p in state.presets) {
        if (p.isDefault != (p.id == id)) {
          final updated = p.copyWith(isDefault: (p.id == id));
          _presetBox.put(updated.id, updated);
        }
      }
      _loadPresets(); // refresh
    }
  }

  void addPreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _presetBox.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _presetBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(
      presets: newPresets,
      activePresetId: state.activePresetId == id ? (newPresets.isNotEmpty ? newPresets.first.id : null) : state.activePresetId,
    );
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main');
});

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return CompilerNotifier(prefs);
});
