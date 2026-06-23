import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/storage_service.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultCompiler;

  SettingsState({
    required this.presets,
    this.activePresetId,
    this.useDefaultCompiler = true,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultCompiler,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(SettingsState(presets: [])) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = _storage.presetsBox;
    List<CompilerPreset> loadedPresets = box.values.toList();

    if (loadedPresets.isEmpty) {
      final defaultPresets = [
        CompilerPreset.blank().copyWith(id: 'one', name: 'OneCompiler', endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run', method: 'POST', authType: 'API-Key Header', stdoutPath: 'stdout', stderrPath: 'stderr', executionTimePath: 'executionTime'),
        CompilerPreset.blank().copyWith(id: 'jd', name: 'JDoodle', endpoint: 'https://api.jdoodle.com/v1/execute', method: 'POST', bodyTemplate: '{"clientId":"...","clientSecret":"...","script":"{code}","stdin":"{stdin}","language":"dart","versionIndex":"4"}', stdoutPath: 'output', stderrPath: 'error', executionTimePath: 'cpuTime', memoryPath: 'memory'),
        CompilerPreset.blank().copyWith(id: 'rep', name: 'Replit', endpoint: '', method: 'POST'),
        CompilerPreset.blank().copyWith(id: 'pis', name: 'Piston', endpoint: 'https://emkc.org/api/v2/piston/execute', method: 'POST', bodyTemplate: '{"language":"dart","version":"3.0.2","files":[{"content":"{code}"}],"stdin":"{stdin}"}', stdoutPath: 'run.stdout', stderrPath: 'run.stderr'),
        CompilerPreset.blank().copyWith(id: 'cdx', name: 'CodeX', endpoint: 'https://api.codex.jaagrav.in', method: 'POST', authType: 'None', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, bodyTemplate: 'code={code}&language=dart&input={stdin}', stdoutPath: 'output', stderrPath: 'error'),
        CompilerPreset.blank().copyWith(id: 'he', name: 'HackerEarth', endpoint: '', method: 'POST'),
        CompilerPreset.blank(), // Blank
      ];
      for (var p in defaultPresets) {
        box.put(p.id, p);
      }
      loadedPresets = defaultPresets;
    }

    final activeId = _storage.settingsBox.get('activePresetId') as String?;
    final useDefault = _storage.settingsBox.get('useDefaultCompiler', defaultValue: true) as bool;

    state = SettingsState(
      presets: loadedPresets,
      activePresetId: activeId,
      useDefaultCompiler: useDefault,
    );
  }

  void setUseDefaultCompiler(bool val) {
    _storage.settingsBox.put('useDefaultCompiler', val);
    state = state.copyWith(useDefaultCompiler: val);
  }

  void setActivePreset(String id) {
    _storage.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _storage.presetsBox.put(preset.id, preset);
    final updated = List<CompilerPreset>.from(state.presets);
    final idx = updated.indexWhere((p) => p.id == preset.id);
    if (idx >= 0) {
      updated[idx] = preset;
    } else {
      updated.add(preset);
    }
    state = state.copyWith(presets: updated);
  }

  void deletePreset(String id) {
    _storage.presetsBox.delete(id);
    final updated = List<CompilerPreset>.from(state.presets)..removeWhere((p) => p.id == id);

    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = updated.isNotEmpty ? updated.first.id : null;
      _storage.settingsBox.put('activePresetId', newActiveId);
    }

    state = state.copyWith(presets: updated, activePresetId: newActiveId);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(StorageService());
});
