import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  PresetState({required this.presets, required this.activePresetId});

  PresetState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  CompilerPreset? get activePreset {
    if (activePresetId.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  late Box<CompilerPreset> _box;
  late Box _prefsBox;
  final _uuid = const Uuid();

  PresetNotifier() : super(PresetState(presets: [], activePresetId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    _prefsBox = await Hive.openBox('app_prefs');

    if (_box.isEmpty) {
      final defaultPresets = _getDefaultPresets();
      for (var p in defaultPresets) {
        await _box.put(p.id, p);
      }
    }

    final presets = _box.values.toList();
    var activeId = _prefsBox.get('active_preset_id', defaultValue: '');

    if (activeId.isEmpty && presets.isNotEmpty) {
      activeId = presets.first.id;
      _prefsBox.put('active_preset_id', activeId);
    }

    state = PresetState(presets: presets, activePresetId: activeId);
  }

  void setActivePreset(String id) {
    _prefsBox.put('active_preset_id', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    if (preset.isReadOnly) return; // Cannot edit read-only presets
    _box.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newPresets = List<CompilerPreset>.from(state.presets);
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      platformName: '${preset.platformName} (Copy)',
      isReadOnly: false,
    );
    addPreset(newPreset);
  }

  void deletePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    if (preset.isReadOnly) return;

    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();

    String newActiveId = state.activePresetId;
    if (id == state.activePresetId && newPresets.isNotEmpty) {
      newActiveId = newPresets.first.id;
      _prefsBox.put('active_preset_id', newActiveId);
    }

    state = PresetState(presets: newPresets, activePresetId: newActiveId);
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: [
          const MapEntry('X-RapidAPI-Key', '{auth}'),
          const MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com'),
          const MapEntry('Content-Type', 'application/json')
        ],
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None', // JDoodle uses body credentials usually, but just an example
        headers: [const MapEntry('Content-Type', 'application/json')],
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": {code}, "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        memoryPath: 'memory',
        executionTimePath: 'cpuTime',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        requestBodyTemplate: '{"language": "dart", "version": "2.19.6", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: [const MapEntry('Content-Type', 'application/json'), const MapEntry('Authorization', 'Bearer {auth}')],
        requestBodyTemplate: '{}',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/x-www-form-urlencoded')],
        requestBodyTemplate: 'code={code}&language=dart',
        stdoutPath: 'output',
        stderrPath: 'error',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        platformName: 'Blank',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        isReadOnly: false,
      ),
    ];
  }
}
