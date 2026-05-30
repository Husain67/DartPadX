import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return presets.isNotEmpty ? presets.first : null;
    }
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [], activePresetId: '', useDefaultOneCompiler: true)) {
    _init();
  }

  void _init() {
    final boxPresets = HiveService.presetsBox.values.toList();
    if (boxPresets.isEmpty) {
      _loadDefaults();
    } else {
      final activeId = HiveService.settingsBox.get('activePresetId', defaultValue: boxPresets.first.id);
      final useDefault = HiveService.settingsBox.get('useDefaultOneCompiler', defaultValue: true);
      state = CompilerState(presets: boxPresets, activePresetId: activeId, useDefaultOneCompiler: useDefault);
    }
  }

  void _loadDefaults() {
    final defaults = [
      CompilerPreset(
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
        responseStdoutPath: 'output',
        responseMemoryPath: 'memory',
        responseTimePath: 'cpuTime',
        isReadOnly: true,
      ),
      CompilerPreset(
        name: 'Piston',
        endpoint: 'https://emacs.piston.rs/api/v2/execute',
        method: 'POST',
        bodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        isReadOnly: true,
      ),
      CompilerPreset(
        name: 'Blank',
        endpoint: 'https://example.com/api',
        method: 'POST',
        isReadOnly: true,
      ),
    ];

    for (var preset in defaults) {
      HiveService.presetsBox.put(preset.id, preset);
    }

    state = CompilerState(
      presets: defaults,
      activePresetId: defaults.first.id,
      useDefaultOneCompiler: true,
    );
    HiveService.settingsBox.put('activePresetId', defaults.first.id);
    HiveService.settingsBox.put('useDefaultOneCompiler', true);
  }

  void toggleUseDefault(bool value) {
    HiveService.settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    HiveService.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    final list = HiveService.presetsBox.values.toList();
    state = state.copyWith(presets: list, activePresetId: preset.id);
    HiveService.settingsBox.put('activePresetId', preset.id);
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    final list = HiveService.presetsBox.values.toList();
    if (list.isNotEmpty) {
      state = state.copyWith(presets: list, activePresetId: list.first.id);
      HiveService.settingsBox.put('activePresetId', list.first.id);
    } else {
      _loadDefaults();
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
