import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final String stdin;
  final bool isOutputVisible;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.stdin = '',
    this.isOutputVisible = false,
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    String? stdin,
    bool? isOutputVisible,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      stdin: stdin ?? this.stdin,
      isOutputVisible: isOutputVisible ?? this.isOutputVisible,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void setStdin(String input) {
    state = state.copyWith(stdin: input);
  }

  void toggleOutputVisibility(bool visible) {
    state = state.copyWith(isOutputVisible: visible);
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', executionTime: '', memory: '');
  }

  Future<void> runCode() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, isOutputVisible: true, stdout: '', stderr: '', executionTime: '', memory: '');

    final compilerState = ref.read(compilerProvider);

    try {
      Map<String, dynamic> result;
      if (compilerState.useDefaultOneCompiler) {
        result = await ApiService.runOneCompiler(activeFile.content, state.stdin);
      } else {
        final activePreset = compilerState.presets.firstWhere(
            (p) => p.id == compilerState.activePresetId,
            orElse: () => throw Exception('No active preset selected'));
        result = await ApiService.runCustomPreset(activePreset, activeFile.content, state.stdin);
      }

      state = state.copyWith(
        isLoading: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        executionTime: result['time'] ?? '',
        memory: result['memory'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        stderr: e.toString(),
      );
    }
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
