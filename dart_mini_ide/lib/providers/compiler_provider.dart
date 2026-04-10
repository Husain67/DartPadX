import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final bool useDefaultOneCompiler;
  final String? selectedPresetId;

  CompilerState({
    required this.presets,
    required this.useDefaultOneCompiler,
    this.selectedPresetId,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefaultOneCompiler,
    String? selectedPresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }

  CompilerPreset? get selectedPreset =>
      presets.cast<CompilerPreset?>().firstWhere((p) => p?.id == selectedPresetId, orElse: () => null);
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  late Box<CompilerPreset> _box;
  late SharedPreferences _prefs;

  CompilerNotifier() : super(CompilerState(presets: [], useDefaultOneCompiler: true)) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    if (_box.isEmpty) {
      _loadInitialPresets();
    }

    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    final selectedId = _prefs.getString('selectedPresetId');

    final presets = _box.values.toList();

    state = CompilerState(
      presets: presets,
      useDefaultOneCompiler: useDefault,
      selectedPresetId: selectedId ?? (presets.isNotEmpty ? presets.first.id : null),
    );
  }

  void _loadInitialPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: const Uuid().v4(),
        platformName: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json',
        },
        queryParams: {},
        requestBodyTemplate: '{"language":"dart","stdin":"{stdin}","files":[{"name":"main.dart","content":"{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        platformName: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET","script":"{code}","stdin":"{stdin}","language":"dart","versionIndex":"0"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        platformName: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{"language":"dart","version":"*","files":[{"name":"main.dart","content":"{code}"}],"stdin":"{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        platformName: 'Blank',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }
  }

  void toggleUseDefault(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setSelectedPreset(String id) {
    _prefs.setString('selectedPresetId', id);
    state = state.copyWith(selectedPresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newSelectedId = state.selectedPresetId;
    if (state.selectedPresetId == id) {
      newSelectedId = newPresets.isNotEmpty ? newPresets.first.id : null;
      if (newSelectedId != null) {
        _prefs.setString('selectedPresetId', newSelectedId);
      } else {
        _prefs.remove('selectedPresetId');
      }
    }
    state = state.copyWith(presets: newPresets, selectedPresetId: newSelectedId);
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      platformName: '${preset.platformName} Copy',
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
    );
    addPreset(newPreset);
  }

  String exportPresets() {
    final list = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(list);
  }

  void importPresets(String jsonStr) {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        // Create new ID on import
        map['id'] = const Uuid().v4();
        final preset = CompilerPreset.fromJson(map);
        addPreset(preset);
      }
    } catch (e) {
      // Ignored for simplicity
    }
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
