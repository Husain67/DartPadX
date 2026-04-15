import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import 'settings_provider.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, List<CompilerPreset>>((ref) {
  return PresetNotifier(ref);
});

class PresetNotifier extends StateNotifier<List<CompilerPreset>> {
  final Ref ref;
  late Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  PresetNotifier(this.ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    if (_box.isEmpty) {
      _loadDefaultPresets();
    } else {
      state = _box.values.toList();
    }
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler (Default API)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'X-RapidAPI-Key': '{authValue}',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston (Engine)',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"language": "dart", "version": "2.19.6", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        bodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit (Mock)',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        authValue: 'YOUR_REPLIT_TOKEN',
        headers: {'Authorization': 'Bearer {authValue}', 'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"replId": "YOUR_REPL_ID", "command": "dart main.dart"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'ram',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'YOUR_CLIENT_SECRET',
        headers: {'client-secret': '{authValue}', 'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        endpointUrl: 'https://api.example.com/run',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'data.stdout',
        stderrPath: 'data.stderr',
        errorPath: 'error',
        executionTimePath: 'data.time',
        memoryPath: 'data.memory',
      ),
    ];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }
    state = _box.values.toList();

    if (state.isNotEmpty) {
      ref.read(settingsProvider.notifier).setSelectedPresetId(state.first.id);
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = _box.values.toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = _box.values.toList();

    final currentSelectedId = ref.read(settingsProvider).selectedPresetId;
    if (currentSelectedId == id) {
      if (state.isNotEmpty) {
        ref.read(settingsProvider.notifier).setSelectedPresetId(state.first.id);
      } else {
        ref.read(settingsProvider.notifier).setSelectedPresetId('');
      }
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newId = _uuid.v4();
    final newPreset = preset.copyWith(
      id: newId,
      name: '${preset.name} (Copy)',
    );
    addPreset(newPreset);
  }

  String exportPresets() {
    final list = state.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      for (var item in list) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        _box.put(preset.id, preset);
      }
      state = _box.values.toList();
    } catch (e) {
      // Handle error gracefully if needed
    }
  }
}
