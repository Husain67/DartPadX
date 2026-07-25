import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({required this.presets, this.activePresetId});

  SettingsState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  SettingsNotifier() : super(SettingsState(presets: [])) {
    _init();
  }

  void _init() {
    _box = Hive.box<CompilerPreset>('compiler_presets');
    var presets = _box.values.toList();

    if (presets.isEmpty) {
      presets = _createDefaultPresets();
      for (var p in presets) {
        _box.put(p.id, p);
      }
    }

    final activePreset = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
    state = SettingsState(presets: presets, activePresetId: activePreset.id);
  }

  List<CompilerPreset> _createDefaultPresets() {
    return [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler (Default)',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authCredentials: const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': '{authCredentials}',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        responseMappings: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': 'memory',
        },
        isDefault: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "0", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "stdin": "{stdin}"}',
        responseMappings: {
          'stdout': 'output',
          'stderr': 'error',
          'executionTime': 'cpuTime',
          'memory': 'memory',
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston (Engine)',
        url: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "3.0.2", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        responseMappings: {
          'stdout': 'run.stdout',
          'stderr': 'run.stderr',
          'error': 'message',
          'executionTime': '',
          'memory': '',
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX API',
        url: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        responseMappings: {
          'stdout': 'output',
          'stderr': 'error',
          'error': 'error',
          'executionTime': 'timestamp',
          'memory': '',
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank Custom',
        url: 'https://',
        method: 'POST',
        authType: 'None',
      )
    ];
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }

  void setActivePreset(String id) {
    final updatedPresets = state.presets.map((p) {
      final isNowDefault = p.id == id;
      final updated = p.copyWith(isDefault: isNowDefault);
      _box.put(updated.id, updated);
      return updated;
    }).toList();

    state = state.copyWith(presets: updatedPresets, activePresetId: id);
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

    String? newActiveId = state.activePresetId;
    if (id == state.activePresetId && updatedPresets.isNotEmpty) {
       newActiveId = updatedPresets.first.id;
       setActivePreset(newActiveId); // Updates Hive default flag
       return; // setActivePreset updates state
    }

    state = state.copyWith(presets: updatedPresets, activePresetId: newActiveId);
  }
}
