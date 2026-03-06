import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String selectedPresetId;
  final bool useDefaultOneCompiler;

  SettingsState({
    required this.presets,
    required this.selectedPresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerPreset? get selectedPreset => presets.cast<CompilerPreset?>().firstWhere(
        (p) => p?.id == selectedPresetId,
        orElse: () => null,
      );

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? selectedPresetId,
    bool? useDefaultOneCompiler,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late Box<CompilerPreset> _presetsBox;
  late SharedPreferences _prefs;
  final _uuid = const Uuid();

  SettingsNotifier() : super(SettingsState(presets: [], selectedPresetId: '', useDefaultOneCompiler: true)) {
    _init();
  }

  Future<void> _init() async {
    _presetsBox = await Hive.openBox<CompilerPreset>('compiler_presets');
    _prefs = await SharedPreferences.getInstance();

    bool useDefault = _prefs.getBool('use_default_compiler') ?? true;
    String selectedId = _prefs.getString('selected_preset_id') ?? '';

    if (_presetsBox.isEmpty) {
      // Pre-load custom compiler API presets
      final initialPresets = [
        CompilerPreset(
          id: _uuid.v4(),
          platformName: 'OneCompiler API',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authValue: 'X-RapidAPI-Key: oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          dynamicHeaders: {
            'Content-Type': 'application/json',
            'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          },
          dynamicQueryParams: {},
          requestBodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: '',
        ),
        CompilerPreset(
          id: _uuid.v4(),
          platformName: 'JDoodle API',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          dynamicHeaders: {'Content-Type': 'application/json'},
          dynamicQueryParams: {},
          requestBodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          errorPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
         CompilerPreset(
          id: _uuid.v4(),
          platformName: 'Piston API',
          endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          dynamicHeaders: {'Content-Type': 'application/json'},
          dynamicQueryParams: {},
          requestBodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
          executionTimePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: _uuid.v4(),
          platformName: 'Blank Template',
          endpointUrl: 'https://example.com/api/run',
          httpMethod: 'POST',
          authType: 'None',
          authValue: '',
          dynamicHeaders: {'Content-Type': 'application/json'},
          dynamicQueryParams: {},
          requestBodyTemplate: '{"code": "{code}"}',
          stdoutPath: 'data.out',
          stderrPath: 'data.err',
          errorPath: 'message',
          executionTimePath: 'time',
          memoryPath: 'mem',
        )
      ];

      for (var p in initialPresets) {
        await _presetsBox.put(p.id, p);
      }

      selectedId = initialPresets.first.id;
      await _prefs.setString('selected_preset_id', selectedId);
    } else {
      if (selectedId.isEmpty || !_presetsBox.containsKey(selectedId)) {
        selectedId = _presetsBox.keys.first.toString();
        await _prefs.setString('selected_preset_id', selectedId);
      }
    }

    state = SettingsState(
      presets: _presetsBox.values.toList(),
      selectedPresetId: selectedId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void toggleUseDefault(bool value) async {
    await _prefs.setBool('use_default_compiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void selectPreset(String id) async {
    await _prefs.setString('selected_preset_id', id);
    state = state.copyWith(selectedPresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final updatedList = [...state.presets];
      updatedList[index] = preset;
      state = state.copyWith(presets: updatedList);
    }
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
    final updatedList = [...state.presets]..removeWhere((p) => p.id == id);

    String newSelectedId = state.selectedPresetId;
    if (newSelectedId == id && updatedList.isNotEmpty) {
      newSelectedId = updatedList.first.id;
      _prefs.setString('selected_preset_id', newSelectedId);
    }

    state = state.copyWith(presets: updatedList, selectedPresetId: newSelectedId);
  }

  void duplicatePreset(String id) {
    final preset = state.presets.cast<CompilerPreset?>().firstWhere((p) => p?.id == id, orElse: () => null);
    if (preset != null) {
      // Must generate new ID for duplicated preset manually
      final newPreset = CompilerPreset(
        id: _uuid.v4(),
        platformName: '${preset.platformName} Copy',
        endpointUrl: preset.endpointUrl,
        httpMethod: preset.httpMethod,
        authType: preset.authType,
        authValue: preset.authValue,
        dynamicHeaders: Map.from(preset.dynamicHeaders),
        dynamicQueryParams: Map.from(preset.dynamicQueryParams),
        requestBodyTemplate: preset.requestBodyTemplate,
        stdoutPath: preset.stdoutPath,
        stderrPath: preset.stderrPath,
        errorPath: preset.errorPath,
        executionTimePath: preset.executionTimePath,
        memoryPath: preset.memoryPath,
      );
      addPreset(newPreset);
    }
  }

  void importPresets(List<CompilerPreset> newPresets) {
    for (var preset in newPresets) {
      // Create new ID to avoid collisions
      final p = preset.copyWith(id: _uuid.v4());
      _presetsBox.put(p.id, p);
    }
    state = state.copyWith(presets: _presetsBox.values.toList());
  }
}
