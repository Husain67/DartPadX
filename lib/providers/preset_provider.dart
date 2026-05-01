import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';
import 'package:uuid/uuid.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  PresetState({
    required this.presets,
    this.activePresetId,
  });

  CompilerPreset? get activePreset {
    if (activePresetId == null || presets.isEmpty) return null;
    return presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
  }

  PresetState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  late final Box<CompilerPreset> _box;

  PresetNotifier() : super(PresetState(presets: [])) {
    _box = HiveService.presetsBox;
    _loadPresets();
  }

  void _loadPresets() {
    final List<CompilerPreset> presets = _box.values.toList();
    if (presets.isEmpty) {
      final defaultPresets = _getDefaultPresets();
      for (var p in defaultPresets) {
        _box.put(p.id, p);
      }
      presets.addAll(defaultPresets);
    }

    state = state.copyWith(
      presets: presets,
      activePresetId: presets.first.id,
    );
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: const [
          MapEntry('X-RapidAPI-Key', 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          MapEntry('Content-Type', 'application/json'),
        ],
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        headers: const [
          MapEntry('Content-Type', 'application/json'),
        ],
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        name: 'Piston',
        url: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        headers: const [
          MapEntry('Content-Type', 'application/json'),
        ],
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        name: 'CodeX',
        url: 'https://api.codex.jaagrav.in',
        method: 'POST',
        headers: const [
          MapEntry('Content-Type', 'application/x-www-form-urlencoded'),
        ],
        bodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        name: 'Replit',
        url: 'https://replit.com/api/v1/run',
        method: 'POST',
      ),
      CompilerPreset(
        name: 'HackerEarth',
        url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
      ),
      CompilerPreset(
        name: 'Blank Preset',
        url: 'https://api.example.com/execute',
      ),
    ];
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updated = _box.values.toList();
    state = state.copyWith(presets: updated, activePresetId: preset.id);
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)'
    );
    _box.put(newPreset.id, newPreset);
    final updated = _box.values.toList();
    state = state.copyWith(presets: updated, activePresetId: newPreset.id);
  }

  void deletePreset(String id) {
    if (_box.length <= 1) return; // Don't delete the last preset
    _box.delete(id);
    final updated = _box.values.toList();
    state = state.copyWith(
      presets: updated,
      activePresetId: state.activePresetId == id ? updated.first.id : state.activePresetId,
    );
  }

  String exportPresets() {
    final List<Map<String, dynamic>> presetList = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(presetList);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (var json in jsonList) {
        final preset = CompilerPreset.fromJson(json);
        // Gen new ID to avoid collisions
        final newPreset = preset.copyWith(id: const Uuid().v4());
        _box.put(newPreset.id, newPreset);
      }
      final updated = _box.values.toList();
      state = state.copyWith(presets: updated);
    } catch (e) {
      // Ignore invalid imports
    }
  }
}
