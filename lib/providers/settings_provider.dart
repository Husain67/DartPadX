import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultOneCompiler,
    required this.activePresetId,
    required this.presets,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences prefs;
  final Box<CompilerPreset> box;

  SettingsNotifier(this.prefs, this.box) : super(SettingsState(
    useDefaultOneCompiler: prefs.getBool('useDefaultOneCompiler') ?? true,
    activePresetId: prefs.getString('activePresetId') ?? '',
    presets: box.values.toList(),
  )) {
    if (state.presets.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Header',
        authValue: 'Your-RapidAPI-Key',
        headers: [
          const MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com'),
          const MapEntry('Content-Type', 'application/json'),
        ],
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        timePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"language": "dart", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'run.error',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit',
        endpoint: 'https://replit.com/api/v1/execute',
        httpMethod: 'POST',
        authType: 'Bearer',
        authValue: 'YOUR_REPLIT_TOKEN',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"language": "dart", "code": "{code}", "stdin": "{stdin}"}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        stdoutPath: 'output',
        stderrPath: 'error',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'Header',
        authValue: 'YOUR_CLIENT_SECRET',
        headers: [const MapEntry('Content-Type', 'application/json'), const MapEntry('client-secret', 'YOUR_CLIENT_SECRET')],
        bodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        timePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpoint: '',
      )
    ];

    for (var preset in defaultPresets) {
      box.put(preset.id, preset);
    }
    state = state.copyWith(presets: box.values.toList());
  }

  void setUseDefaultOneCompiler(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    box.put(preset.id, preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    box.put(preset.id, preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void deletePreset(String id) {
    box.delete(id);
    if (state.activePresetId == id) {
      setActivePreset('');
    }
    state = state.copyWith(presets: box.values.toList());
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final box = Hive.box<CompilerPreset>('presets');
  return SettingsNotifier(prefs, box);
});
