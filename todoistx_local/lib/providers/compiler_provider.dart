import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  CompilerState({required this.presets, required this.activePresetId});

  CompilerPreset get activePreset {
    return presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
  }

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final _uuid = const Uuid();
  late SharedPreferences _prefs;

  CompilerNotifier() : super(CompilerState(presets: [], activePresetId: '')) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    final defaultOneCompiler = CompilerPreset(
      id: 'default_oc',
      name: 'OneCompiler (Default)',
      endpoint: '',
      isDefaultPreset: true,
    );

    final String? presetsJson = _prefs.getString('compiler_presets');
    final String? activeId = _prefs.getString('active_preset_id');

        final defaultCustomPresets = [
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '{\n  "clientId": "",\n  "clientSecret": "",\n  "script": "{code}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston (Engine)',
        endpoint: 'https://emacs.ch/api/v2/execute',
        httpMethod: 'POST',
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: 'replit',
        name: 'Replit',
        endpoint: '',
      ),
      CompilerPreset(
        id: 'codex',
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        stderrPath: 'error',
      ),
      CompilerPreset(
        id: 'hackerearth',
        name: 'HackerEarth',
        endpoint: '',
      ),
    ];

    List<CompilerPreset> loadedPresets = [defaultOneCompiler];

    if (presetsJson == null) {
      loadedPresets.addAll(defaultCustomPresets);
    } else {
      try {
        final List<dynamic> decoded = json.decode(presetsJson);
        loadedPresets.addAll(decoded.map((e) => CompilerPreset.fromMap(e)).where((p) => p.id != 'default_oc'));
      } catch (e) {
        // Fallback
      }
    }

    state = CompilerState(
      presets: loadedPresets,
      activePresetId: activeId ?? 'default_oc',
    );
  }

  Future<void> _saveToPrefs() async {
    final customPresets = state.presets.where((p) => !p.isDefaultPreset).toList();
    final jsonStr = json.encode(customPresets.map((e) => e.toMap()).toList());
    await _prefs.setString('compiler_presets', jsonStr);
    await _prefs.setString('active_preset_id', state.activePresetId);
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
    _saveToPrefs();
  }

  void addPreset(CompilerPreset preset) {
    final p = preset.copyWith(id: _uuid.v4());
    state = state.copyWith(presets: [...state.presets, p]);
    _saveToPrefs();
  }

  void updatePreset(CompilerPreset preset) {
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updated);
    _saveToPrefs();
  }

  void deletePreset(String id) {
    if (id == 'default_oc') return; // Cannot delete default
    final updated = state.presets.where((p) => p.id != id).toList();
    String nextId = state.activePresetId;
    if (state.activePresetId == id) {
      nextId = 'default_oc';
    }
    state = state.copyWith(presets: updated, activePresetId: nextId);
    _saveToPrefs();
  }
}
