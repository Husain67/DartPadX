
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
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
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true, presets: [])) {
    _init();
  }

  late Box<CompilerPreset> _presetBox;
  late SharedPreferences _prefs;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _presetBox = Hive.box<CompilerPreset>('presets');

    if (_presetBox.isEmpty) {
      _loadBuiltInPresets();
    }

    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      presets: _presetBox.values.toList(),
    );
  }

  void _loadBuiltInPresets() {
    final builtIn = [
      CompilerPreset(
        id: 'oc_default',
        name: 'OneCompiler (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: [
          MapEntry('content-type', 'application/json'),
          MapEntry('x-rapidapi-host', 'onecompiler-apis.p.rapidapi.com'),
        ],
        queryParams: [],
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isBuiltIn: true,
      ),
      CompilerPreset(
        id: 'piston_default',
        name: 'Piston (Emacs)',
        endpointUrl: 'https://emacsx.com/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: [
          MapEntry('Content-Type', 'application/json'),
        ],
        queryParams: [],
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": {code}}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
        isBuiltIn: true,
      ),
    ];

    for (var preset in builtIn) {
      _presetBox.put(preset.id, preset);
    }
  }

  Future<void> toggleDefaultCompiler(bool useDefault) async {
    await _prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> savePreset(CompilerPreset preset) async {
    await _presetBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetBox.values.toList());
  }

  Future<void> deletePreset(String id) async {
    await _presetBox.delete(id);
    if (state.activePresetId == id) {
      await _prefs.remove('activePresetId');
      state = state.copyWith(activePresetId: null, presets: _presetBox.values.toList());
    } else {
      state = state.copyWith(presets: _presetBox.values.toList());
    }
  }

  Future<void> duplicatePreset(String id) async {
    final preset = _presetBox.get(id);
    if (preset == null) return;

    final newId = const Uuid().v4();
    final duplicated = CompilerPreset(
      id: newId,
      name: '${preset.name} (Copy)',
      endpointUrl: preset.endpointUrl,
      httpMethod: preset.httpMethod,
      authType: preset.authType,
      authValue: preset.authValue,
      headers: List.from(preset.headers),
      queryParams: List.from(preset.queryParams),
      bodyTemplate: preset.bodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      executionTimePath: preset.executionTimePath,
      memoryPath: preset.memoryPath,
      isBuiltIn: false,
    );
    await savePreset(duplicated);
  }
}
