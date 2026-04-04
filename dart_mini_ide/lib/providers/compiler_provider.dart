import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String selectedPresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    required this.selectedPresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerPreset? get selectedPreset {
    if (presets.isEmpty) return null;
    try {
      return presets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return presets.first;
    }
  }

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? selectedPresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(
    presets: [],
    selectedPresetId: '',
    useDefaultOneCompiler: true,
  )) {
    _init();
  }

  Box<CompilerPreset>? _box;
  SharedPreferences? _prefs;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final useDefault = _prefs?.getBool('useDefaultOneCompiler') ?? true;
    state = state.copyWith(useDefaultOneCompiler: useDefault);
    await _loadPresets();
  }
  final _uuid = const Uuid();

  Future<void> _loadPresets() async {
    _box = Hive.box<CompilerPreset>('compiler_presets');

    if (_box!.isEmpty) {
      _loadDefaultPresets();
    } else {
      final presets = _box!.values.toList();
      state = state.copyWith(
        presets: presets,
        selectedPresetId: presets.first.id,
      );
    }
  }

  void _loadDefaultPresets() {
    final oneCompiler = CompilerPreset(
      id: _uuid.v4(),
      platformName: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authKey: 'X-RapidAPI-Key',
      authValue: const String.fromEnvironment('RAPID_API_KEY', defaultValue: 'YOUR_API_KEY'),
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      requestBodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "index.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    );

    final piston = CompilerPreset(
      id: _uuid.v4(),
      platformName: 'Piston',
      endpointUrl: 'https://emkc.org/api/v2/piston/execute',
      httpMethod: 'POST',
      requestBodyTemplate: '{"language": "{language}", "version": "*", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
      stdoutPath: 'run.stdout',
      stderrPath: 'run.stderr',
      errorPath: 'compile.stderr',
    );

    final presets = [oneCompiler, piston];
    for (var p in presets) {
      _box?.put(p.id, p);
    }

    state = state.copyWith(
      presets: presets,
      selectedPresetId: presets.first.id,
    );
  }

  void addPreset(CompilerPreset preset) {
    _box?.put(preset.id, preset);
    state = state.copyWith(
      presets: [...state.presets, preset],
      selectedPresetId: preset.id,
    );
  }

  void updatePreset(CompilerPreset preset) {
    _box?.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _box?.delete(id);
    final remaining = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(
      presets: remaining,
      selectedPresetId: remaining.isNotEmpty ? remaining.first.id : '',
    );
  }

  void duplicatePreset(CompilerPreset preset) {
      final newId = _uuid.v4();
      final duplicated = preset.copyWith(id: newId, platformName: '${preset.platformName} (Copy)');
      addPreset(duplicated);
  }

  void selectPreset(String id) {
    state = state.copyWith(selectedPresetId: id);
  }

  void toggleDefaultOneCompiler(bool useDefault) {
    _prefs?.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  String exportPresetsJson() {
      final list = state.presets.map((p) => {
          'platformName': p.platformName,
          'endpointUrl': p.endpointUrl,
          'httpMethod': p.httpMethod,
          'authType': p.authType,
          'authKey': p.authKey,
          'authValue': p.authValue,
          'headers': p.headers,
          'queryParams': p.queryParams,
          'requestBodyTemplate': p.requestBodyTemplate,
          'defaultLanguage': p.defaultLanguage,
          'stdoutPath': p.stdoutPath,
          'stderrPath': p.stderrPath,
          'errorPath': p.errorPath,
          'executionTimePath': p.executionTimePath,
          'memoryPath': p.memoryPath,
      }).toList();
      return jsonEncode(list);
  }

  void importPresetsJson(String jsonStr) {
      try {
          final list = jsonDecode(jsonStr) as List;
          for (var item in list) {
              final map = item as Map<String, dynamic>;
              final preset = CompilerPreset(
                  id: _uuid.v4(),
                  platformName: map['platformName'] ?? 'Imported',
                  endpointUrl: map['endpointUrl'] ?? '',
                  httpMethod: map['httpMethod'] ?? 'POST',
                  authType: map['authType'] ?? 'None',
                  authKey: map['authKey'] ?? '',
                  authValue: map['authValue'] ?? '',
                  headers: Map<String, String>.from(map['headers'] ?? {}),
                  queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
                  requestBodyTemplate: map['requestBodyTemplate'] ?? '',
                  defaultLanguage: map['defaultLanguage'] ?? 'dart',
                  stdoutPath: map['stdoutPath'] ?? 'stdout',
                  stderrPath: map['stderrPath'] ?? 'stderr',
                  errorPath: map['errorPath'] ?? 'error',
                  executionTimePath: map['executionTimePath'] ?? 'time',
                  memoryPath: map['memoryPath'] ?? 'memory',
              );
              addPreset(preset);
          }
      } catch (e) {
          // Ignore invalid JSON
      }
  }
}
