import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';
import 'file_provider.dart';
import 'compiler_provider.dart';
import 'settings_provider.dart';

final compilerServiceProvider = Provider<CompilerService>((ref) => CompilerService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String? stdout;
  final String? stderr;
  final String? error;
  final String? executionTime;
  final String? memory;
  final bool isPanelExpanded;

  ExecutionState({
    this.isRunning = false,
    this.stdout,
    this.stderr,
    this.error,
    this.executionTime,
    this.memory,
    this.isPanelExpanded = false,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    bool? isPanelExpanded,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      isPanelExpanded: isPanelExpanded ?? this.isPanelExpanded,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref _ref;

  ExecutionNotifier(this._ref) : super(ExecutionState());

  void setPanelExpanded(bool expanded) {
    state = state.copyWith(isPanelExpanded: expanded);
  }

  void clearOutput() {
    state = ExecutionState(isPanelExpanded: state.isPanelExpanded);
  }

  Future<void> runCode() async {
    final file = _ref.read(fileProvider.notifier).activeFile;
    if (file == null) return;

    final settings = _ref.read(settingsProvider);
    final compilerState = _ref.read(compilerProvider.notifier);

    final activePreset = settings.useDefaultOneCompiler
        ? _getDefaultOneCompilerPreset(compilerState.state.presets)
        : compilerState.activePreset;

    if (activePreset == null) {
      state = state.copyWith(error: 'No active compiler preset found.', isPanelExpanded: true);
      return;
    }

    state = state.copyWith(isRunning: true, isPanelExpanded: true, stdout: null, stderr: null, error: null);

    final service = _ref.read(compilerServiceProvider);

    // Simplistic stdin handling for now: if you want stdin, you'll need a UI for it.
    // We'll pass empty for this exact requirement unless added later.
    final result = await service.executeCode(file.content, "", activePreset);

    state = state.copyWith(
      isRunning: false,
      stdout: result['stdout'],
      stderr: result['stderr'],
      error: result['error'],
      executionTime: result['executionTime'],
      memory: result['memory'],
    );
  }

  // Helper to fallback safely if they delete the default preset
  dynamic _getDefaultOneCompilerPreset(List<dynamic> presets) {
     try {
       return presets.firstWhere((p) => p.name.toLowerCase().contains('onecompiler'));
     } catch (_) {
       if (presets.isNotEmpty) return presets.first;
       return null;
     }
  }
}
