import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'compiler_provider.dart';
import 'files_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(WidgetRef ref, String stdinInput) async {
    final filesState = ref.read(filesProvider);
    final compilerState = ref.read(compilerProvider);

    final code = filesState.activeFile?.content ?? '';
    if (code.isEmpty) return;

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', error: 'Executing...', time: '', memory: '');

    ExecutionResult result;

    if (compilerState.useDefaultOneCompiler) {
      result = await ApiService.executeOneCompiler(code, stdinInput);
    } else {
      final activePreset = compilerState.activePreset;
      if (activePreset == null) {
        state = state.copyWith(isRunning: false, error: 'No custom preset selected.');
        return;
      }
      result = await ApiService.executeCode(code: code, stdin: stdinInput, preset: activePreset);
    }

    state = state.copyWith(
      isRunning: false,
      stdout: result.stdout,
      stderr: result.stderr,
      error: result.error,
      time: result.executionTime,
      memory: result.memory,
    );
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
