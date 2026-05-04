import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final List<CompilerPreset> presets;
  final String activePresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    required this.presets,
    required this.activePresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(
    useDefaultOneCompiler: true,
    presets: [],
    activePresetId: '',
  ));

  late Box _box;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _box = await Hive.openBox('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    bool useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    String activeId = _prefs.getString('activePresetId') ?? '';

    List<CompilerPreset> loadedPresets = [];
    for (var key in _box.keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      loadedPresets.add(CompilerPreset.fromMap(map));
    }

    if (loadedPresets.isEmpty) {
      loadedPresets = _getDefaultPresets();
      for (var p in loadedPresets) {
        await _box.put(p.id, p.toMap());
      }
    }

    if (activeId.isEmpty && loadedPresets.isNotEmpty) {
      activeId = loadedPresets.first.id;
    }

    state = SettingsState(
      useDefaultOneCompiler: useDefault,
      presets: loadedPresets,
      activePresetId: activeId,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleDefaultOneCompiler(bool value) async {
    await _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset.toMap());
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset.toMap());
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updated);
  }

  Future<void> deletePreset(String id) async {
    await _box.delete(id);
    final updated = state.presets.where((p) => p.id != id).toList();
    String newActiveId = state.activePresetId;
    if (newActiveId == id && updated.isNotEmpty) {
      newActiveId = updated.first.id;
      await _prefs.setString('activePresetId', newActiveId);
    }
    state = state.copyWith(presets: updated, activePresetId: newActiveId);
  }

  Future<void> duplicatePreset(CompilerPreset preset) async {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '\${preset.name} (Copy)',
      isReadOnly: false,
    );
    await addPreset(newPreset);
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler API',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM=')),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        },
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint: 'https://emacsx.com/api/v2/execute', // Example public instance
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpoint: 'https://replit.com/api/v1/run',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        stdoutPath: 'output',
        errorPath: 'error',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_SECRET'},
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpoint: 'https://api.example.com/run',
      ),
    ];
  }
}
