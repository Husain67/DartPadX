import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, List<CompilerPreset>>((ref) {
  return CompilerNotifier();
});

final activeCompilerIdProvider = StateProvider<String?>((ref) {
  final presets = ref.watch(compilerProvider);
  if (presets.isEmpty) return null;

  // Read default from SharedPreferences, synchronously if we could, but here we just return the first one or default.
  // We'll update this in the UI initialization to fetch the actual preference.
  return presets.first.id;
});

class CompilerNotifier extends StateNotifier<List<CompilerPreset>> {
  final Box<CompilerPreset> _box = Hive.box<CompilerPreset>('compiler_presets');

  CompilerNotifier() : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    if (_box.isEmpty) {
      _initializeDefaultPresets();
    }
    state = _box.values.toList();
  }

  void _initializeDefaultPresets() {
    final presets = [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler (Default)',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'Header',
        headers: [
          {'key': 'x-rapidapi-key', 'value': const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac')},
          {'key': 'x-rapidapi-host', 'value': 'onecompiler-apis.p.rapidapi.com'},
          {'key': 'Content-Type', 'value': 'application/json'},
        ],
        queryParams: [],
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": {code}\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: [{'key': 'Content-Type', 'value': 'application/json'}],
        queryParams: [],
        bodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": {code},\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        url: 'https://api.example.com/run',
        method: 'POST',
        authType: 'None',
        headers: [],
        queryParams: [],
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];

    for (var preset in presets) {
      _box.put(preset.id, preset);
    }
  }

  CompilerPreset? getPreset(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.map((p) => p.id == preset.id ? preset : p).toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }

  void duplicatePreset(String id) {
    final existing = getPreset(id);
    if (existing != null) {
      final newPreset = existing.copyWith(
        id: const Uuid().v4(),
        name: '${existing.name} (Copy)'
      );
      addPreset(newPreset);
    }
  }
}
