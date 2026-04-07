import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final bool sheetVisible;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.sheetVisible = false,
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    bool? sheetVisible,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      sheetVisible: sheetVisible ?? this.sheetVisible,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning() {
    state = state.copyWith(
      isLoading: true,
      sheetVisible: true,
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );
  }

  void setOutput({
    required String stdout,
    required String stderr,
    required String time,
    required String memory,
  }) {
    state = state.copyWith(
      isLoading: false,
      stdout: stdout,
      stderr: stderr,
      executionTime: time,
      memory: memory,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      isLoading: false,
      stderr: error,
    );
  }

  void clearOutput() {
    state = state.copyWith(
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );
  }

  void setSheetVisible(bool visible) {
    state = state.copyWith(sheetVisible: visible);
  }
}
