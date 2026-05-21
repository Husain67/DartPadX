import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset_model.dart';

const String _presetsBoxName = 'presetsBox';
const String _useDefaultOcKey = 'useDefaultOneCompiler';
const String _selectedPresetIdKey = 'selectedPresetId';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPresetModel> presets;
  final bool useDefaultOneCompiler;
  final String? selectedPresetId;

  PresetState({
    required this.presets,
    required this.useDefaultOneCompiler,
    this.selectedPresetId,
  });

  PresetState copyWith({
    List<CompilerPresetModel>? presets,
    bool? useDefaultOneCompiler,
    String? selectedPresetId,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  PresetNotifier() : super(PresetState(presets: [], useDefaultOneCompiler: true));

  late Box<CompilerPresetModel> _presetsBox;
  late Box _prefsBox;
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _presetsBox = Hive.box<CompilerPresetModel>(_presetsBoxName);
    _prefsBox = Hive.box('prefsBox');

    bool useDefault = _prefsBox.get(_useDefaultOcKey, defaultValue: true);
    String? selectedId = _prefsBox.get(_selectedPresetIdKey);

    List<CompilerPresetModel> loadedPresets = _presetsBox.values.toList();

    if (loadedPresets.isEmpty) {
      loadedPresets = _getDefaultPresets();
      for (var p in loadedPresets) {
        await _presetsBox.put(p.id, p);
      }
    }

    if (selectedId == null || !loadedPresets.any((p) => p.id == selectedId)) {
      selectedId = loadedPresets.first.id;
      await _prefsBox.put(_selectedPresetIdKey, selectedId);
    }

    state = PresetState(
      presets: loadedPresets,
      useDefaultOneCompiler: useDefault,
      selectedPresetId: selectedId,
    );
  }

  void toggleUseDefault(bool useDefault) {
    _prefsBox.put(_useDefaultOcKey, useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void selectPreset(String id) {
    _prefsBox.put(_selectedPresetIdKey, id);
    state = state.copyWith(selectedPresetId: id);
  }

  Future<void> addPreset(CompilerPresetModel preset) async {
    await _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  Future<void> updatePreset(CompilerPresetModel preset) async {
    await _presetsBox.put(preset.id, preset);
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updated);
  }

  Future<void> deletePreset(String id) async {
    await _presetsBox.delete(id);
    final updated = state.presets.where((p) => p.id != id).toList();

    String? nextId = state.selectedPresetId;
    if (state.selectedPresetId == id && updated.isNotEmpty) {
      nextId = updated.first.id;
      _prefsBox.put(_selectedPresetIdKey, nextId);
    }
    state = state.copyWith(presets: updated, selectedPresetId: nextId);
  }

  CompilerPresetModel? get activePreset {
    if (state.useDefaultOneCompiler) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.selectedPresetId);
    } catch (e) {
      return null;
    }
  }

  List<CompilerPresetModel> _getDefaultPresets() {
    return [
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'OneCompiler API',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'Header API Key',
        headers: {
          'x-rapidapi-key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        outputMappingPath: 'stdout',
        errorMappingPath: 'stderr',
        executionTimeMappingPath: 'executionTime',
        memoryMappingPath: '',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId": "YOUR_ID", "clientSecret": "YOUR_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        outputMappingPath: 'output',
        errorMappingPath: 'error',
        executionTimeMappingPath: 'cpuTime',
        memoryMappingPath: 'memory',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'Piston (EngineerMan)',
        url: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
        outputMappingPath: 'run.stdout',
        errorMappingPath: 'run.stderr',
        executionTimeMappingPath: '',
        memoryMappingPath: '',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'Replit',
        url: 'https://replit.com/api/execute',
        method: 'POST',
        authType: 'Bearer Token',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        outputMappingPath: '',
        errorMappingPath: '',
        executionTimeMappingPath: '',
        memoryMappingPath: '',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'CodeX',
        url: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}", "language": "dart", "input": "{stdin}"}',
        outputMappingPath: 'output',
        errorMappingPath: 'error',
        executionTimeMappingPath: 'info',
        memoryMappingPath: '',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'HackerEarth',
        url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        authType: 'Header API Key',
        headers: {'client-secret': 'YOUR_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}"}',
        outputMappingPath: 'result.run_status.output',
        errorMappingPath: 'result.run_status.stderr',
        executionTimeMappingPath: 'result.run_status.time_used',
        memoryMappingPath: 'result.run_status.memory_used',
      ),
      CompilerPresetModel(
        id: _uuid.v4(),
        name: 'Blank Preset',
        url: '',
        method: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{"code": "{code}"}',
        outputMappingPath: '',
        errorMappingPath: '',
        executionTimeMappingPath: '',
        memoryMappingPath: '',
      )
    ];
  }
}
