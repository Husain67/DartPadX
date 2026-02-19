import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';

class SettingsState {
  final CompilerPreset? activePreset;
  final List<CompilerPreset> presets;

  SettingsState({this.activePreset, this.presets = const []});

  SettingsState copyWith({CompilerPreset? activePreset, List<CompilerPreset>? presets}) {
    return SettingsState(
      activePreset: activePreset ?? this.activePreset,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Box<CompilerPreset>? _presetsBox;
  Box? _settingsBox;

  Future<void> _init() async {
    _presetsBox = await Hive.openBox<CompilerPreset>('compiler_presets');
    _settingsBox = await Hive.openBox('settings');

    // Add default presets if empty
    if (_presetsBox!.isEmpty) {
      await _presetsBox!.addAll([
        CompilerPreset(
          name: 'JDoodle',
          endpoint: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '{\n  "script": "{code}",\n  "language": "dart",\n  "versionIndex": "3",\n  "clientId": "YOUR_ID",\n  "clientSecret": "YOUR_SECRET"\n}',
          responseMapping: {'stdout': 'output', 'executionTime': 'cpuTime', 'memory': 'memory'},
        ),
        CompilerPreset(
          name: 'Piston',
          endpoint: 'https://emkc.org/api/v2/piston/execute',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
          responseMapping: {'stdout': 'run.stdout', 'stderr': 'run.stderr'},
        ),
        CompilerPreset(
          name: 'CodeX',
          endpoint: 'https://api.codex.jaagrav.in',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
          responseMapping: {'stdout': 'output', 'error': 'error'},
        ),
        CompilerPreset(
          name: 'HackerEarth',
          endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          method: 'POST',
          authType: 'None',
          headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_SECRET'},
          queryParams: {},
          bodyTemplate: '{\n  "source": "{code}",\n  "lang": "DART",\n  "input": "{stdin}"\n}',
          responseMapping: {'stdout': 'result.run_status.output', 'stderr': 'result.run_status.stderr', 'executionTime': 'result.run_status.time_used', 'memory': 'result.run_status.memory_used'},
        ),
      ]);
    }

    _updateState();
  }

  void _updateState() {
    final activePresetKey = _settingsBox!.get('active_preset_key');
    CompilerPreset? activePreset;

    // Find active preset by key
    if (activePresetKey != null && _presetsBox!.containsKey(activePresetKey)) {
      activePreset = _presetsBox!.get(activePresetKey);
    }

    state = SettingsState(
      activePreset: activePreset,
      presets: _presetsBox!.values.toList(),
    );
  }

  Future<void> setActivePreset(CompilerPreset? preset) async {
    if (preset != null) {
      if (preset.isInBox) {
        await _settingsBox!.put('active_preset_key', preset.key);
      }
    } else {
      await _settingsBox!.delete('active_preset_key');
    }
    _updateState();
  }

  Future<void> savePreset(CompilerPreset preset) async {
    if (preset.isInBox) {
      await preset.save();
    } else {
      await _presetsBox!.add(preset);
    }
    _updateState();
  }

  Future<void> deletePreset(CompilerPreset preset) async {
    if (state.activePreset == preset) {
      await setActivePreset(null);
    }
    if (preset.isInBox) {
      await preset.delete();
    }
    _updateState();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
