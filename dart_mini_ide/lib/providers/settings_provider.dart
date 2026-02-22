import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/storage_service.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useCustomPreset;

  SettingsState({
    this.presets = const [],
    this.activePresetId,
    this.useCustomPreset = false,
  });

  CompilerPreset? get activePreset {
    if (presets.isEmpty) return null;
    return presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = StorageService(); // Or ref.read(storageServiceProvider)
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final presets = _storage.getAllPresets();
    final activeId = _storage.getActivePresetId();
    final useCustom = _storage.getUseCustomPreset();

    if (presets.isEmpty) {
      // Default presets
      final defaultPresets = [
        CompilerPreset(
          name: 'JDoodle (Dart)',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          requestBodyTemplate: '{"clientId": "...", "clientSecret": "...", "script": "{code}", "language": "dart", "versionIndex": "4"}',
          stdoutPath: 'output',
        ),
         CompilerPreset(
          name: 'Piston (Dart)',
          endpointUrl: 'https://emkc.org/api/v2/piston/execute',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
        ),
      ];
      for (final p in defaultPresets) {
        _storage.savePreset(p);
      }
      state = SettingsState(
        presets: defaultPresets,
        activePresetId: activeId ?? defaultPresets.first.id,
        useCustomPreset: useCustom,
      );
    } else {
      state = SettingsState(
        presets: presets,
        activePresetId: activeId ?? presets.first.id,
        useCustomPreset: useCustom,
      );
    }
  }

  void addPreset(CompilerPreset preset) {
    _storage.savePreset(preset);
    state = SettingsState(
      presets: [...state.presets, preset],
      activePresetId: state.activePresetId,
      useCustomPreset: state.useCustomPreset,
    );
  }

  void updatePreset(CompilerPreset preset) {
    _storage.savePreset(preset);
    state = SettingsState(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
      activePresetId: state.activePresetId,
      useCustomPreset: state.useCustomPreset,
    );
  }

  void deletePreset(String id) {
    _storage.deletePreset(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = remaining.isNotEmpty ? remaining.first.id : null;
      _storage.saveActivePresetId(newActiveId);
    }
    state = SettingsState(
      presets: remaining,
      activePresetId: newActiveId,
      useCustomPreset: state.useCustomPreset,
    );
  }

  void setActivePreset(String id) {
    _storage.saveActivePresetId(id);
    state = SettingsState(
      presets: state.presets,
      activePresetId: id,
      useCustomPreset: state.useCustomPreset,
    );
  }

  void toggleUseCustomPreset(bool value) {
    _storage.saveUseCustomPreset(value);
    state = SettingsState(
      presets: state.presets,
      activePresetId: state.activePresetId,
      useCustomPreset: value,
    );
  }
}
