import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../services/storage_service.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefault; // toggle Default vs Custom

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefault = true,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefault,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefault: useDefault ?? this.useDefault,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() async {
    final loaded = StorageService.getPresets();
    final defaultOneCompiler = CompilerPreset(
      id: 'default_onecompiler',
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      headers: [
        {'key': 'X-RapidAPI-Key', 'value': const String.fromEnvironment('API_KEY')},
        {'key': 'X-RapidAPI-Host', 'value': 'onecompiler-apis.p.rapidapi.com'},
        {'key': 'Content-Type', 'value': 'application/json'},
      ],
      bodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
      isReadOnly: true,
    );

    final jdoodle = CompilerPreset(
      id: 'jdoodle',
      name: 'JDoodle',
      endpointUrl: 'https://api.jdoodle.com/v1/execute',
      httpMethod: 'POST',
      authType: 'None',
      bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "{language}", "versionIndex": "4"}',
      stdoutPath: 'output',
      stderrPath: 'error',
      errorPath: 'error',
      executionTimePath: 'cpuTime',
      memoryPath: 'memory',
      isReadOnly: true,
    );

    final piston = CompilerPreset(
      id: 'piston',
      name: 'Piston',
      endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
      httpMethod: 'POST',
      authType: 'None',
      bodyTemplate: '{"language": "{language}", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'message',
      executionTimePath: '',
      memoryPath: '',
      isReadOnly: true,
    );

    final replit = CompilerPreset(id: 'replit', name: 'Replit', endpointUrl: 'https://replit.com/api/...', isReadOnly: true);
    final codex = CompilerPreset(id: 'codex', name: 'CodeX', endpointUrl: 'https://api.codex.jaagrav.in', isReadOnly: true);
    final hackerEarth = CompilerPreset(id: 'hackerearth', name: 'HackerEarth', endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/', isReadOnly: true);
    final blank = CompilerPreset(id: 'blank', name: 'Blank Template', endpointUrl: 'https://', isReadOnly: false);

    final presets = <CompilerPreset>[defaultOneCompiler, jdoodle, piston, replit, codex, hackerEarth, blank];

    if (loaded.isEmpty) {
      for (var p in presets) {
        StorageService.savePreset(p);
      }
      state = state.copyWith(presets: presets, activePresetId: defaultOneCompiler.id);
    } else {
      // Ensure default exists
      if (!loaded.any((p) => p.id == defaultOneCompiler.id)) {
         StorageService.savePreset(defaultOneCompiler);
         loaded.insert(0, defaultOneCompiler);
      }

      final useDefStr = await StorageService.getString('useDefaultCompiler') ?? 'true';
      final activeId = await StorageService.getString('activePresetId') ?? defaultOneCompiler.id;

      state = state.copyWith(
        presets: loaded,
        activePresetId: activeId,
        useDefault: useDefStr == 'true',
      );
    }
  }

  void savePreset(CompilerPreset preset) {
    StorageService.savePreset(preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    final newPresets = List<CompilerPreset>.from(state.presets);
    if (index != -1) {
      newPresets[index] = preset;
    } else {
      newPresets.add(preset);
    }
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    StorageService.deletePreset(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : null;
      if (newActiveId != null) {
        StorageService.setString('activePresetId', newActiveId);
      }
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    StorageService.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id, useDefault: false);
    StorageService.setString('useDefaultCompiler', 'false');
  }

  void setUseDefault(bool use) {
    StorageService.setString('useDefaultCompiler', use.toString());
    state = state.copyWith(useDefault: use);
  }

  CompilerPreset? get activePreset {
    if (state.useDefault) {
      return state.presets.firstWhere((p) => p.id == 'default_onecompiler', orElse: () => state.presets.first);
    }
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return state.presets.isNotEmpty ? state.presets.first : null;
    }
  }
}
