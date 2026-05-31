import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/storage_service.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
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
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    final boxPresets = StorageService.presetsBox.values.toList();
    final useDefault = StorageService.settingsBox.get('useDefaultOneCompiler', defaultValue: true);
    final activeId = StorageService.settingsBox.get('activePresetId');

    if (boxPresets.isEmpty) {
      final defaultPresets = _getPreloadedPresets();
      for (var preset in defaultPresets) {
        StorageService.presetsBox.put(preset.id, preset);
      }
      state = CompilerState(
        presets: defaultPresets,
        useDefaultOneCompiler: useDefault,
        activePresetId: activeId ?? defaultPresets.first.id,
      );
    } else {
      state = CompilerState(
        presets: boxPresets,
        useDefaultOneCompiler: useDefault,
        activePresetId: activeId,
      );
    }
  }

  List<CompilerPreset> _getPreloadedPresets() {
    return [
      CompilerPreset(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "index.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{\n  "clientId": "your_client_id",\n  "clientSecret": "your_client_secret",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        timePath: 'cpuTime',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        name: 'Piston',
        endpointUrl: 'https://emacsx.com/api/v2/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        isPreloaded: true,
      ),
      CompilerPreset(name: 'Replit', endpointUrl: '', isPreloaded: true),
      CompilerPreset(name: 'CodeX', endpointUrl: '', isPreloaded: true),
      CompilerPreset(name: 'HackerEarth', endpointUrl: '', isPreloaded: true),
      CompilerPreset(name: 'Blank', endpointUrl: '', isPreloaded: true),
    ];
  }

  void toggleDefault(bool value) {
    StorageService.settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    StorageService.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    StorageService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    StorageService.presetsBox.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    StorageService.presetsBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(
        presets: newPresets,
        activePresetId: state.activePresetId == id ? (newPresets.isNotEmpty ? newPresets.first.id : null) : state.activePresetId);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
