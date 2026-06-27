import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/preset_model.dart';
import 'package:uuid/uuid.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<PresetModel> presets;
  final String? activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    this.activePresetId,
    this.useDefaultOneCompiler = true,
  });

  CompilerState copyWith({
    List<PresetModel>? presets,
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
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  Box<PresetModel>? _box;
  Box? _settingsBox;
  final _uuid = const Uuid();

  CompilerState get currentState => state;

  Future<void> _loadPresets() async {
    _box = Hive.box<PresetModel>('presets');
    _settingsBox = Hive.box('settings');

    List<PresetModel> presets = _box!.values.toList();

    if (presets.isEmpty) {
      presets = _getInitialPresets();
      for (var p in presets) {
        await _box!.put(p.id, p);
      }
    }

    final activeId = _settingsBox!.get('activePresetId') as String?;
    final useOneCompiler = _settingsBox!.get('useDefaultOneCompiler', defaultValue: true) as bool;

    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useOneCompiler,
    );
  }

  List<PresetModel> _getInitialPresets() {
    return [
      PresetModel(
        id: _uuid.v4(),
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'content-type': 'application/json',
        },
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        timePath: 'executionTime',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        bodyTemplate: '{"script": "{code}", "language": "dart", "versionIndex": "0", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
        stdoutPath: 'output',
        errorPath: 'error',
        timePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      PresetModel(
        id: _uuid.v4(),
        name: 'Piston',
        endpoint: 'https://emacs.piston.rs/api/v2/execute',
        bodyTemplate: '{"language": "dart", "version": "3.3.3", "files": [{"content": "{code}"}]}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      PresetModel(id: _uuid.v4(), name: 'Replit', endpoint: ''),
      PresetModel(id: _uuid.v4(), name: 'CodeX', endpoint: ''),
      PresetModel(id: _uuid.v4(), name: 'HackerEarth', endpoint: ''),
      PresetModel(id: _uuid.v4(), name: 'Blank', endpoint: ''),
    ];
  }

  void addPreset(PresetModel preset) {
    _box!.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(PresetModel preset) {
    _box!.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newPresets = [...state.presets];
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    }
  }

  void deletePreset(String id) {
    _box!.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = null;
      _settingsBox!.delete('activePresetId');
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void setActivePreset(String? id) {
    _settingsBox!.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void setUseDefaultOneCompiler(bool useDefault) {
    _settingsBox!.put('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }
}
