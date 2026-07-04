import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final CompilerPreset activePreset;

  CompilerState({required this.presets, required this.activePreset});

  CompilerState copyWith({List<CompilerPreset>? presets, CompilerPreset? activePreset}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _presetsBox = Hive.box<CompilerPreset>('presets');

  CompilerNotifier() : super(_getInitialState()) {
    if (_presetsBox.isEmpty) {
      _initDefaultPresets();
    }
  }

  static CompilerState _getInitialState() {
    final box = Hive.box<CompilerPreset>('presets');
    if (box.isEmpty) {
      final defaultPreset = _createOneCompilerPreset();
      return CompilerState(presets: [defaultPreset], activePreset: defaultPreset);
    } else {
      final presets = box.values.toList();
      final active = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
      return CompilerState(presets: presets, activePreset: active);
    }
  }

  void _initDefaultPresets() {
    final oneCompiler = _createOneCompilerPreset();
    _presetsBox.put(oneCompiler.id, oneCompiler);

    state = CompilerState(presets: [oneCompiler], activePreset: oneCompiler);
  }

  static CompilerPreset _createOneCompilerPreset() {
    return CompilerPreset(
      id: const Uuid().v4(),
      name: 'OneCompiler (Default)',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      headers: {
        'content-type': 'application/json',
        'X-RapidAPI-Key': const String.fromEnvironment('RAPID_API_KEY', defaultValue: ''),
      },
      queryParams: {},
      requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
      responseStdoutPath: 'stdout',
      responseStderrPath: 'stderr',
      responseErrorPath: 'exception',
      responseTimePath: 'executionTime',
      responseMemoryPath: '',
      isDefault: true,
    );
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final updated = List<CompilerPreset>.from(state.presets)..add(preset);
    state = state.copyWith(presets: updated);
  }

  void updatePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    CompilerPreset active = state.activePreset;
    if (preset.id == active.id) {
      active = preset;
    }
    state = state.copyWith(presets: updated, activePreset: active);
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
    final updated = state.presets.where((p) => p.id != id).toList();
    if (state.activePreset.id == id && updated.isNotEmpty) {
      setActivePreset(updated.first.id);
    } else {
      state = state.copyWith(presets: updated);
    }
  }

  void setActivePreset(String id) {
    final newActive = state.presets.firstWhere((p) => p.id == id);

    // Update isDefault flags in DB
    for (var p in state.presets) {
      if (p.isDefault) {
        final updatedP = p.copyWith(isDefault: false);
        _presetsBox.put(p.id, updatedP);
      }
    }

    final updatedNewActive = newActive.copyWith(isDefault: true);
    _presetsBox.put(updatedNewActive.id, updatedNewActive);

    final updatedPresets = state.presets.map((p) {
      if (p.id == updatedNewActive.id) return updatedNewActive;
      if (p.isDefault) return p.copyWith(isDefault: false);
      return p;
    }).toList();

    state = state.copyWith(presets: updatedPresets, activePreset: updatedNewActive);
  }
}
