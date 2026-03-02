import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultCompiler;
  final CompilerPreset? selectedPreset;
  final List<CompilerPreset> presets;

  SettingsState({
    this.useDefaultCompiler = true,
    this.selectedPreset,
    this.presets = const [],
  });

  SettingsState copyWith({
    bool? useDefaultCompiler,
    CompilerPreset? selectedPreset,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    final useDefault = Hive.box('settings').get('use_default_compiler', defaultValue: true);
    final selectedId = Hive.box('settings').get('selected_preset_id');

    List<CompilerPreset> loadedPresets = box.values.toList();
    if (loadedPresets.isEmpty) {
      _loadInitialPresets();
      loadedPresets = box.values.toList();
    }

    CompilerPreset? selectedPreset;
    if (selectedId != null) {
      selectedPreset = loadedPresets.firstWhere(
        (p) => p.id == selectedId,
        orElse: () => loadedPresets.first,
      );
    }

    state = state.copyWith(
      useDefaultCompiler: useDefault,
      presets: loadedPresets,
      selectedPreset: selectedPreset,
    );
  }

  void _loadInitialPresets() {
    final box = Hive.box<CompilerPreset>('compiler_presets');

    box.put(
      'onecompiler',
      CompilerPreset(
        id: 'onecompiler',
        platformName: 'OneCompiler API',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Key': const String.fromEnvironment('ONECOMPILER_KEY', defaultValue: 'YOUR_SECURE_API_KEY'),
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
    );

    box.put(
      'jdoodle',
      CompilerPreset(
        id: 'jdoodle',
        platformName: 'JDoodle API',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0", "stdin": "{stdin}"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
    );

    box.put(
      'piston',
      CompilerPreset(
        id: 'piston',
        platformName: 'Piston API',
        endpointUrl: 'https://emacs.ch/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "3.5.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      ),
    );

    box.put(
      'replit',
      CompilerPreset(
        id: 'replit',
        platformName: 'Replit (Custom)',
        endpointUrl: 'https://your-replit-url.repl.co/run',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}", "language": "dart"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    );

    box.put(
      'codex',
      CompilerPreset(
        id: 'codex',
        platformName: 'CodeX API',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        queryParams: {},
        requestBodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    );

    box.put(
      'hackerearth',
      CompilerPreset(
        id: 'hackerearth',
        platformName: 'HackerEarth API',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'client-secret': 'YOUR_CLIENT_SECRET', 'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
    );

    box.put(
      'blank',
      CompilerPreset(
        id: 'blank',
        platformName: 'Blank Custom API',
        endpointUrl: 'https://api.example.com/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'content-type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: 'time',
        memoryPath: 'memory',
      ),
    );
  }

  void toggleCompilerMode(bool useDefault) {
    Hive.box('settings').put('use_default_compiler', useDefault);
    state = state.copyWith(useDefaultCompiler: useDefault);
  }

  void selectPreset(CompilerPreset preset) {
    Hive.box('settings').put('selected_preset_id', preset.id);
    state = state.copyWith(selectedPreset: preset);
  }

  void addPreset(CompilerPreset preset) {
    Hive.box<CompilerPreset>('compiler_presets').put(preset.id, preset);
    _loadSettings();
  }

  void removePreset(String id) {
    Hive.box<CompilerPreset>('compiler_presets').delete(id);
    _loadSettings();
  }

  void updatePreset(CompilerPreset preset) {
    Hive.box<CompilerPreset>('compiler_presets').put(preset.id, preset);
    _loadSettings();
  }
}
