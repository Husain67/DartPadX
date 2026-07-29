import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPreset> presets;
  final bool useDefault;
  final String? selectedPresetId;

  PresetState({
    required this.presets,
    this.useDefault = true,
    this.selectedPresetId,
  });

  PresetState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefault,
    String? selectedPresetId,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      useDefault: useDefault ?? this.useDefault,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }

  CompilerPreset? get selectedPreset {
    if (selectedPresetId == null || presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return null;
    }
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier() : super(PresetState(presets: [])) {
    _loadPresets();
  }

  late Box _box;
  late Box _settings;

  void _loadPresets() {
    _box = Hive.box('presetsBox');
    _settings = Hive.box('settingsBox');

    List<CompilerPreset> loaded = [];
    final keys = _box.keys;
    for (var key in keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      loaded.add(CompilerPreset.fromMap(map));
    }

    if (loaded.isEmpty) {
      final initialPresets = [
        CompilerPreset(
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
          stdoutPath: 'output',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          name: 'Piston',
          endpointUrl: 'https://emkc.org/api/v2/piston/execute',
          httpMethod: 'POST',
          requestBodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
        ),
        CompilerPreset(
          name: 'CodeX',
          endpointUrl: 'https://api.codex.jaagrav.in',
          httpMethod: 'POST',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
          stdoutPath: 'output',
          errorPath: 'error',
        ),
        CompilerPreset(
          name: 'HackerEarth',
          endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          headers: {'client-secret': 'YOUR_API_KEY'},
          requestBodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          executionTimePath: 'result.run_status.time_used',
        ),

        CompilerPreset(name: 'Blank', endpointUrl: 'https://'),
      ];
      for (var p in initialPresets) {
        loaded.add(p);
        _box.put(p.id, p.toMap());
      }
    }

    final useDefault = _settings.get('useDefaultCompiler', defaultValue: true);
    final selectedId = _settings.get('selectedPresetId');

    state = PresetState(
      presets: loaded,
      useDefault: useDefault,
      selectedPresetId: selectedId,
    );
  }

  void addPreset(CompilerPreset preset) {
    final newPresets = [...state.presets, preset];
    _box.put(preset.id, preset.toMap());
    state = state.copyWith(presets: newPresets);
  }

  void updatePreset(CompilerPreset preset) {
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    _box.put(preset.id, preset.toMap());
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();

    String? newSelectedId = state.selectedPresetId;
    if (newSelectedId == id) {
      newSelectedId = newPresets.isNotEmpty ? newPresets.first.id : null;
      _settings.put('selectedPresetId', newSelectedId);
    }

    state = state.copyWith(presets: newPresets, selectedPresetId: newSelectedId);
  }

  void setUseDefault(bool val) {
    _settings.put('useDefaultCompiler', val);
    state = state.copyWith(useDefault: val);
  }

  void setSelectedPreset(String id) {
    _settings.put('selectedPresetId', id);
    state = state.copyWith(selectedPresetId: id);
  }

  String exportPresets() {
    final data = state.presets.map((p) => p.toMap()).toList();
    return jsonEncode(data);
  }

  void importPresets(String jsonStr) {
    try {
      final List<dynamic> data = jsonDecode(jsonStr);
      for (var item in data) {
         final map = Map<String, dynamic>.from(item);
         final preset = CompilerPreset.fromMap(map);
         _box.put(preset.id, preset.toMap());
         state = state.copyWith(presets: [...state.presets, preset]);
      }
    } catch (e) {
      // ignore
    }
  }
}
