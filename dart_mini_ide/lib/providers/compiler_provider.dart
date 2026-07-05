import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compiler_preset.dart';
import '../core/constants.dart';

class CompilerState {
  final List<CompilerPreset> presets;
  final CompilerPreset activePreset;

  CompilerState({
    required this.presets,
    required this.activePreset,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    CompilerPreset? activePreset,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;

  CompilerNotifier(this._box) : super(_initializeState(_box));

  static CompilerState _initializeState(Box<CompilerPreset> box) {
    if (box.isEmpty) {
      final presets = [
        CompilerPreset(
          name: 'OneCompiler (Default)',
          endpointUrl: AppConstants.defaultOneCompilerUrl,
          httpMethod: 'POST',
          headers: AppConstants.defaultHeaders,
          bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          executionTimePath: 'executionTime',
          memoryPath: 'memory',
          isDefault: true,
        ),
        CompilerPreset(
          name: 'JDoodle',
          endpointUrl: 'https://api.jdoodle.com/v1/execute',
          httpMethod: 'POST',
          bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
          stdoutPath: 'output',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          name: 'Piston',
          endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
          httpMethod: 'POST',
          bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
        ),
        CompilerPreset(
          name: 'Replit',
          endpointUrl: 'https://replit.com/api/v1/repls/YOUR_REPL_ID/execute',
          httpMethod: 'POST',
        ),
        CompilerPreset(
          name: 'CodeX',
          endpointUrl: 'https://api.codex.jaagrav.in',
          httpMethod: 'POST',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          bodyTemplate: 'code={code}&language=dart&input={stdin}',
          stdoutPath: 'output',
          errorPath: 'error',
        ),
        CompilerPreset(
          name: 'HackerEarth',
          endpointUrl: 'https://api.hackerearth.com/v3/code/run/',
          httpMethod: 'POST',
        ),
      ];

      for (var p in presets) {
        box.put(p.id, p);
      }
    }

    final presets = box.values.toList();
    final defaultP = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);

    return CompilerState(presets: presets, activePreset: defaultP);
  }

  void setActivePreset(String id) {
    final newActive = state.presets.where((p) => p.id == id).firstOrNull;
    if (newActive != null) {
      state = state.copyWith(activePreset: newActive);

      // Update isDefault in Hive
      for(var p in state.presets) {
        if(p.id == id) {
          p.isDefault = true;
          _box.put(p.id, p);
        } else if (p.isDefault) {
          p.isDefault = false;
          _box.put(p.id, p);
        }
      }
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedList = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(
      presets: updatedList,
      activePreset: state.activePreset.id == preset.id ? preset : state.activePreset,
    );
  }

  void deletePreset(String id) {
    if (state.presets.length <= 1) return; // Don't delete last one

    _box.delete(id);
    final updatedList = state.presets.where((p) => p.id != id).toList();

    CompilerPreset active = state.activePreset;
    if (active.id == id) {
      active = updatedList.first;
      active.isDefault = true;
      _box.put(active.id, active);
    }

    state = state.copyWith(presets: updatedList, activePreset: active);
  }
}

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) {
  return Hive.box<CompilerPreset>(AppConstants.hivePresetBox);
});

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = ref.watch(compilerBoxProvider);
  return CompilerNotifier(box);
});
