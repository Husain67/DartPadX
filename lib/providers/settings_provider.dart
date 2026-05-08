import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
    required this.presets,
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

  CompilerPreset? get activePreset {
    if (activePresetId == null) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true, presets: [])) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = prefs.getString('activePresetId');

    final box = HiveService.presetsBox;
    final loadedPresets = box.values.toList();

    if (loadedPresets.isEmpty) {
      final defaultPresets = [
        CompilerPreset(id: 'one', name: 'OneCompiler', endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run', responseMapping: ResponseMapping()),
        CompilerPreset(id: 'jdoodle', name: 'JDoodle', endpointUrl: 'https://api.jdoodle.com/v1/execute', responseMapping: ResponseMapping(stdoutPath: 'output', stderrPath: 'error', executionTimePath: 'cpuTime', memoryPath: 'memory')),
        CompilerPreset(id: 'piston', name: 'Piston', endpointUrl: 'https://emacsx.com/api/v2/execute', responseMapping: ResponseMapping(stdoutPath: 'run.stdout', stderrPath: 'run.stderr', errorPath: 'compile.stderr')),
        CompilerPreset(id: 'replit', name: 'Replit', endpointUrl: 'https://replit.com/api/v1/execute', responseMapping: ResponseMapping()),
        CompilerPreset(id: 'codex', name: 'CodeX', endpointUrl: 'https://api.codex.com/run', responseMapping: ResponseMapping()),
        CompilerPreset(id: 'hackerearth', name: 'HackerEarth', endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/', responseMapping: ResponseMapping()),
        CompilerPreset(id: 'blank', name: 'Blank', endpointUrl: '', responseMapping: ResponseMapping()),
      ];
      for (var p in defaultPresets) {
          box.put(p.id, p);
      }
      loadedPresets.addAll(defaultPresets);
    }


    state = SettingsState(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      presets: loadedPresets,
    );
  }

  Future<void> toggleDefaultCompiler(bool useDefault) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  Future<void> setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : null;
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
