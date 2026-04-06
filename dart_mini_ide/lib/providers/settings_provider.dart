import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    this.useDefaultOneCompiler = true,
    this.activePresetId,
    this.presets = const [],
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  static const String _useDefaultKey = 'useDefaultOneCompiler';
  static const String _activePresetIdKey = 'activePresetId';
  late Box<CompilerPreset> _presetBox;
  late SharedPreferences _prefs;

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _presetBox = Hive.box<CompilerPreset>('presets');

    if (_presetBox.isEmpty) {
      _loadInitialPresets();
    }

    final useDefault = _prefs.getBool(_useDefaultKey) ?? true;
    final activeId = _prefs.getString(_activePresetIdKey);

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      presets: _presetBox.values.toList(),
    );
  }

  void _loadInitialPresets() {
    final presets = [
      CompilerPreset.create(
        name: 'OneCompiler API (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': const String.fromEnvironment('RAPID_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        bodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset.create(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset.create(
        name: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'run.error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset.create(
        name: 'Replit',
        endpointUrl: 'https://api.replit.com/v1/execute',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json', 'Authorization': 'YOUR_REPLIT_TOKEN'},
        bodyTemplate: '{"language": "dart", "code": "{code}", "stdin": "{stdin}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset.create(
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset.create(
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_CLIENT_SECRET'},
        bodyTemplate: '{"lang": "DART", "source": "{code}", "input": "{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'errors',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset.create(
        name: 'Blank Preset',
        endpointUrl: '',
      ),
    ];

    for (var preset in presets) {
      _presetBox.put(preset.id, preset);
    }
  }

  Future<void> toggleUseDefault(bool value) async {
    await _prefs.setBool(_useDefaultKey, value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString(_activePresetIdKey, id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> savePreset(CompilerPreset preset) async {
    await _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetBox.values.toList());
    if (state.activePresetId == null) {
      setActivePreset(preset.id);
    }
  }

  Future<void> deletePreset(String id) async {
    await _presetBox.delete(id);
    final presets = _presetBox.values.toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = presets.isNotEmpty ? presets.first.id : null;
      if (newActiveId != null) {
        await _prefs.setString(_activePresetIdKey, newActiveId);
      } else {
        await _prefs.remove(_activePresetIdKey);
      }
    }
    state = state.copyWith(presets: presets, activePresetId: newActiveId);
  }

  Future<void> duplicatePreset(CompilerPreset preset) async {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)',
    );
    await savePreset(newPreset);
  }

  String exportPresetsJson() {
    final list = state.presets.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  Future<void> importPresetsJson(String jsonStr) async {
    try {
      final list = jsonDecode(jsonStr) as List;
      for (var item in list) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        await _presetBox.put(preset.id, preset);
      }
      state = state.copyWith(presets: _presetBox.values.toList());
    } catch (e) {
      rethrow;
    }
  }
}
