import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../core/db.dart';

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
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier()
      : super(CompilerState(
          presets: [],
          activePresetId: '',
          useDefaultOneCompiler: true,
        )) {
    _init();
  }

  void _init() {
    final box = DB.presetsBox;
    List<CompilerPreset> loadedPresets = box.values.toList();

    if (loadedPresets.isEmpty) {
      loadedPresets = _getDefaultPresets();
      for (var p in loadedPresets) {
        box.put(p.id, p);
      }
    }

    final activeId = DB.settingsBox.get('activePresetId', defaultValue: loadedPresets.first.id);
    final useDefault = DB.settingsBox.get('useDefaultOneCompiler', defaultValue: true);

    state = CompilerState(
      presets: loadedPresets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        bodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ]
}''',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '''{
  "clientId": "your_client_id_here",
  "clientSecret": "your_client_secret_here",
  "script": "{code}",
  "stdin": "{stdin}",
  "language": "dart",
  "versionIndex": "0"
}''',
        stdoutPath: 'output',
        stderrPath: '',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        url: 'https://emacsx.com/api/v2/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '''{
  "language": "dart",
  "version": "*",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ],
  "stdin": "{stdin}"
}''',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        url: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        url: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        url: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        url: '',
        isPreloaded: true,
      ),
    ];
  }

  CompilerPreset? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (e) {
      return null;
    }
  }

  void setUseDefaultOneCompiler(bool value) {
    DB.settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    DB.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    DB.presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      final newPresets = List<CompilerPreset>.from(state.presets);
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    } else {
      state = state.copyWith(presets: [...state.presets, preset]);
    }
  }

  void deletePreset(String id) {
    DB.presetsBox.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String newActiveId = state.activePresetId;
    if (state.activePresetId == id && newPresets.isNotEmpty) {
      newActiveId = newPresets.first.id;
      DB.settingsBox.put('activePresetId', newActiveId);
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void duplicatePreset(String id) {
     final preset = state.presets.firstWhere((p) => p.id == id);
     final duplicated = preset.copyWith(
       id: const Uuid().v4(),
       name: '${preset.name} (Copy)',
       isPreloaded: false,
     );
     savePreset(duplicated);
  }

  String exportPresets() {
    final list = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(list);
  }

  void importPresets(String jsonStr) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      for (var item in decoded) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        savePreset(preset.copyWith(id: const Uuid().v4(), isPreloaded: false));
      }
    } catch (e) {
      // Import fail silently or handle in UI
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
