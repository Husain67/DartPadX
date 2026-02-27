import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/compiler_preset.dart';
import '../../data/repositories/compiler_service.dart';

// Service
final compilerServiceProvider = Provider<CompilerService>((ref) => CompilerService());

// Presets State
final compilerPresetsProvider = StateNotifierProvider<CompilerPresetsNotifier, List<CompilerPreset>>((ref) {
  final box = Hive.box<CompilerPreset>('presets');
  return CompilerPresetsNotifier(box);
});

class CompilerPresetsNotifier extends StateNotifier<List<CompilerPreset>> {
  final Box<CompilerPreset> _box;

  CompilerPresetsNotifier(this._box) : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    if (_box.isEmpty) {
      final defaults = CompilerPreset.defaultPresets;
      for (var p in defaults) {
        _box.put(p.id, p);
      }
      state = defaults;
    } else {
      state = _box.values.toList();
    }
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.map((p) => p.id == preset.id ? preset : p).toList();
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }
}

// Current Selected Preset
final selectedPresetProvider = StateProvider<CompilerPreset>((ref) {
  final presets = ref.watch(compilerPresetsProvider);
  if (presets.isEmpty) {
    // Should ideally not happen if defaults are loaded, but just in case
    return CompilerPreset.defaultPresets.first;
  }
  // Default to OneCompiler
  return presets.firstWhere((p) => p.id == 'onecompiler', orElse: () => presets.first);
});

// Execution State
class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String? error;
  final String? executionTime;
  final String? memoryUsage;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.error,
    this.executionTime,
    this.memoryUsage,
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memoryUsage,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memoryUsage: memoryUsage ?? this.memoryUsage,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final CompilerService _service;
  final Ref _ref;

  ExecutionNotifier(this._service, this._ref) : super(ExecutionState());

  Future<void> execute(String code) async {
    final preset = _ref.read(selectedPresetProvider);
    state = state.copyWith(isLoading: true, stdout: '', stderr: '', error: null);

    try {
      final result = await _service.executeCode(code: code, preset: preset);

      state = state.copyWith(
        isLoading: false,
        stdout: result.stdout,
        stderr: result.stderr,
        error: result.error,
        executionTime: result.executionTime,
        memoryUsage: result.memoryUsage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        stderr: 'Execution Exception: \$e',
      );
    }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final service = ref.watch(compilerServiceProvider);
  return ExecutionNotifier(service, ref);
});
