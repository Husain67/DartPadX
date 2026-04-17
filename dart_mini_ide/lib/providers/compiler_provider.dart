
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
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
  final Box<CompilerPreset> _box;
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  CompilerNotifier(this._box, this._prefs) : super(CompilerState(presets: _box.values.toList())) {
    _loadPrefs();
    if (state.presets.isEmpty) {
      _loadInitialPresets();
    }
  }

  void _loadPrefs() {
    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = _prefs.getString('activePresetId');

    // verify activeId exists
    bool exists = false;
    if (activeId != null) {
      exists = state.presets.any((p) => p.id == activeId);
    }

    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: exists ? activeId : (state.presets.isNotEmpty ? state.presets.first.id : null),
    );
  }

  Future<void> _loadInitialPresets() async {
    final defaultPresets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler API',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'X-RapidAPI-Key: oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        requestBodyTemplate: '{"language":"dart", "stdin":"{stdin}", "files":[{"name":"main.dart", "content":{code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle API',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId":"YOUR_CLIENT_ID", "clientSecret":"YOUR_CLIENT_SECRET", "script":{code}, "language":"dart", "versionIndex":"4"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: '',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isReadOnly: true,
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank Template',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isReadOnly: false,
      ),
    ];

    for (var p in defaultPresets) {
      await _box.put(p.id, p);
    }

    state = state.copyWith(presets: _box.values.toList());
    if (state.activePresetId == null && state.presets.isNotEmpty) {
      setActivePreset(state.presets.first.id);
    }
  }

  Future<void> toggleUseDefault(bool val) async {
    await _prefs.setBool('useDefaultOneCompiler', val);
    state = state.copyWith(useDefaultOneCompiler: val);
  }

  Future<void> setActivePreset(String id) async {
    await _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    _box.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();

    String? nextId = state.activePresetId;
    if (state.activePresetId == id) {
      nextId = remaining.isNotEmpty ? remaining.first.id : null;
      if (nextId != null) {
        _prefs.setString('activePresetId', nextId);
      } else {
        _prefs.remove('activePresetId');
      }
    }

    state = state.copyWith(presets: remaining, activePresetId: nextId);
  }

  void duplicatePreset(CompilerPreset preset) {
     final newPreset = CompilerPreset(
        id: _uuid.v4(),
        name: '${preset.name} (Copy)',
        endpointUrl: preset.endpointUrl,
        httpMethod: preset.httpMethod,
        authType: preset.authType,
        authValue: preset.authValue,
        headers: Map.from(preset.headers),
        queryParams: Map.from(preset.queryParams),
        requestBodyTemplate: preset.requestBodyTemplate,
        stdoutPath: preset.stdoutPath,
        stderrPath: preset.stderrPath,
        errorPath: preset.errorPath,
        executionTimePath: preset.executionTimePath,
        memoryPath: preset.memoryPath,
        isReadOnly: false,
     );
     savePreset(newPreset);
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

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) => Hive.box<CompilerPreset>('presets'));
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref.read(compilerBoxProvider), ref.read(sharedPrefsProvider));
});
