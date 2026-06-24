
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';


const String _kCompilerBox = 'compilerBox';
const String _kPrefsBox = 'prefsBox';
const String _kSelectedCompilerId = 'selectedCompilerId';
const String _kUseDefaultCompiler = 'useDefaultCompiler';


final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultCompiler = true,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  late Box<CompilerPreset> _box;
  late Box _prefsBox;

  CompilerNotifier() : super(CompilerState(presets: []));

  CompilerState get currentState => state;

  Future<void> init() async {
    _box = await Hive.openBox<CompilerPreset>(_kCompilerBox);
    _prefsBox = await Hive.openBox(_kPrefsBox);

    List<CompilerPreset> loadedPresets = _box.values.toList();
    if (loadedPresets.isEmpty) {
      loadedPresets = _getDefaultPresets();
      for (var preset in loadedPresets) {
        await _box.put(preset.id, preset);
      }
    }

    String? savedActiveId = _prefsBox.get(_kSelectedCompilerId);
    if (savedActiveId == null || !loadedPresets.any((p) => p.id == savedActiveId)) {
      savedActiveId = loadedPresets.first.id;
      _prefsBox.put(_kSelectedCompilerId, savedActiveId);
    }

    bool useDefault = _prefsBox.get(_kUseDefaultCompiler, defaultValue: true);

    state = CompilerState(
      presets: loadedPresets,
      activePresetId: savedActiveId,
      useDefaultCompiler: useDefault,
    );
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: 'onecompiler',
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'content-type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'X-RapidAPI-Key': const String.fromEnvironment('ONECOMPILER_API_KEY', defaultValue: ''),
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        responseStdoutPath: 'stdout',
        responseStderrPath: 'stderr',
        responseErrorPath: 'exception',
        responseExecutionTimePath: 'executionTime',
        responseMemoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: 'error',
        responseExecutionTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston',
        endpointUrl: 'https://emacsx.com/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "2.19.6", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
        responseErrorPath: 'run.error',
        responseExecutionTimePath: '',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'replit',
        name: 'Replit',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        responseStdoutPath: '',
        responseStderrPath: '',
        responseErrorPath: '',
        responseExecutionTimePath: '',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'codex',
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseErrorPath: 'error',
        responseExecutionTimePath: '',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'hackerearth',
        name: 'HackerEarth',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        responseStdoutPath: '',
        responseStderrPath: '',
        responseErrorPath: '',
        responseExecutionTimePath: '',
        responseMemoryPath: '',
      ),
      CompilerPreset(
        id: 'blank',
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        responseStdoutPath: '',
        responseStderrPath: '',
        responseErrorPath: '',
        responseExecutionTimePath: '',
        responseMemoryPath: '',
      ),
    ];
  }

  void setUseDefaultCompiler(bool value) {
    _prefsBox.put(_kUseDefaultCompiler, value);
    state = state.copyWith(useDefaultCompiler: value);
  }

  void setActivePreset(String id) {
    if (state.presets.any((p) => p.id == id)) {
      _prefsBox.put(_kSelectedCompilerId, id);
      state = state.copyWith(activePresetId: id);
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final newPresets = [...state.presets, preset];
    state = state.copyWith(presets: newPresets);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: newPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id && newPresets.isNotEmpty) {
      newActiveId = newPresets.first.id;
      _prefsBox.put(_kSelectedCompilerId, newActiveId);
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }
}
