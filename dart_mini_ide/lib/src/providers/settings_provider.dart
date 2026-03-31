import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultApi;
  final String? selectedPresetId;

  SettingsState({
    this.useDefaultApi = true,
    this.selectedPresetId,
  });

  SettingsState copyWith({
    bool? useDefaultApi,
    String? selectedPresetId,
  }) {
    return SettingsState(
      useDefaultApi: useDefaultApi ?? this.useDefaultApi,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<String> _box;

  SettingsNotifier() : super(SettingsState()) {
    _box = Hive.box<String>('settings');
    _loadSettings();
  }

  void _loadSettings() {
    final useDef = _box.get('useDefaultApi', defaultValue: 'true') == 'true';
    final selectedId = _box.get('selectedPresetId');
    state = SettingsState(
      useDefaultApi: useDef,
      selectedPresetId: selectedId,
    );
  }

  void setUseDefaultApi(bool value) {
    _box.put('useDefaultApi', value.toString());
    state = state.copyWith(useDefaultApi: value);
  }

  void setSelectedPresetId(String? id) {
    if (id != null) {
      _box.put('selectedPresetId', id);
    } else {
      _box.delete('selectedPresetId');
    }
    state = state.copyWith(selectedPresetId: id);
  }
}

final presetsProvider = StateNotifierProvider<PresetsNotifier, List<CompilerPreset>>((ref) {
  return PresetsNotifier();
});

class PresetsNotifier extends StateNotifier<List<CompilerPreset>> {
  late Box<CompilerPreset> _box;

  PresetsNotifier() : super([]) {
    _box = Hive.box<CompilerPreset>('compiler_presets');
    _loadPresets();
  }

  void _loadPresets() {
    final items = _box.values.toList();
    if (items.isEmpty) {
      final oneCompiler = CompilerPreset.create(
        platformName: 'OneCompiler (Custom)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'X-RapidAPI-Key:oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      );

      final jdoodle = CompilerPreset.create(
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      );

      final piston = CompilerPreset.create(
        platformName: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      );

      final replit = CompilerPreset.create(
        platformName: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/execute',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'Authorization:Bearer YOUR_REPLIT_TOKEN',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "code": "{code}"\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      );

      final codex = CompilerPreset.create(
        platformName: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      );

      final hackerEarth = CompilerPreset.create(
        platformName: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'client-secret:YOUR_SECRET_KEY',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "source": "{code}",\n  "lang": "DART"\n}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      );

      final blank = CompilerPreset.create(
        platformName: 'Blank Preset',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'output.stdout',
        stderrPath: 'output.stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      );

      final defaultPresets = [oneCompiler, jdoodle, piston, replit, codex, hackerEarth, blank];

      for (var p in defaultPresets) {
        _box.put(p.id, p);
      }
      items.addAll(defaultPresets);
    }
    state = items;
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    preset.save();
    state = state.map((p) => p.id == preset.id ? preset : p).toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }
}
