import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../models/response_mapping.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  CompilerState({required this.presets, this.activePresetId});

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  CompilerPreset? get activePreset {
    if (activePresetId == null || presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (e) {
      return presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
    }
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  CompilerState get currentState => state;

  void _loadPresets() {
    final box = HiveService.getPresetsBox();
    final settingsBox = HiveService.getSettingsBox();

    if (box.isEmpty) {
      _initializeDefaultPresets();
    }

    List<CompilerPreset> loadedPresets = box.values.toList();

    final lastActiveId = settingsBox.get('active_preset_id');
    final activeId = loadedPresets.any((p) => p.id == lastActiveId)
        ? lastActiveId
        : Constants.defaultPresetId;

    state = state.copyWith(presets: loadedPresets, activePresetId: activeId);
  }

  void _initializeDefaultPresets() {
    final box = HiveService.getPresetsBox();

    final defaults = [
      CompilerPreset(
        id: Constants.defaultPresetId,
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'X-RapidAPI-Key': Constants.oneCompilerApiKey,
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "index.dart", "content": "{code}"}]}',
        responseMapping: ResponseMapping(
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          timePath: 'executionTime',
          memoryPath: '',
        ),
        isDefault: true,
        isReadOnly: false,
      ),
      CompilerPreset(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'Basic Auth',
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        responseMapping: ResponseMapping(
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'statusCode',
          timePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        isReadOnly: false,
      ),
      CompilerPreset(
        name: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        requestBodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        responseMapping: ResponseMapping(
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          timePath: '',
          memoryPath: '',
        ),
        isReadOnly: false,
      ),
      CompilerPreset(
        name: 'Blank Preset',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        requestBodyTemplate: '{}',
        responseMapping: ResponseMapping(
          stdoutPath: '', stderrPath: '', errorPath: '', timePath: '', memoryPath: ''
        ),
        isReadOnly: false,
      ),
    ];

    for (var preset in defaults) {
      box.put(preset.id, preset);
    }
  }

  void setActivePreset(String id) {
    if (state.presets.any((p) => p.id == id)) {
      HiveService.getSettingsBox().put('active_preset_id', id);
      state = state.copyWith(activePresetId: id);
    }
  }

  void savePreset(CompilerPreset preset) {
    HiveService.getPresetsBox().put(preset.id, preset);

    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    if (!newPresets.any((p) => p.id == preset.id)) {
      newPresets.add(preset);
    }

    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id, orElse: () => state.presets.first);
    if (preset.isDefault) return; // Prevent deleting the core default

    HiveService.getPresetsBox().delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();

    String nextActiveId = state.activePresetId ?? Constants.defaultPresetId;
    if (id == state.activePresetId) {
      nextActiveId = newPresets.isNotEmpty ? newPresets.first.id : Constants.defaultPresetId;
    }

    HiveService.getSettingsBox().put('active_preset_id', nextActiveId);
    state = state.copyWith(presets: newPresets, activePresetId: nextActiveId);
  }

  void duplicatePreset(String id) {
    final original = state.presets.firstWhere((p) => p.id == id);
    final duplicate = original.copyWith(
      id: const Uuid().v4(),
      name: '${original.name} (Copy)',
      isDefault: false,
      isReadOnly: false,
    );
    savePreset(duplicate);
  }

  String exportPresets() {
    final presetsJson = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(presetsJson);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      for (var item in decoded) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        savePreset(preset.copyWith(id: const Uuid().v4(), isDefault: false, isReadOnly: false));
      }
    } catch (e) {
      // Handle error, e.g., throw exception to be caught by UI
      throw Exception('Invalid JSON format');
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
