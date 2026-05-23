import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setExecuting(bool executing) {
    state = state.copyWith(isExecuting: executing);
  }

  void setResult({
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    state = state.copyWith(
      isExecuting: false,
      stdout: stdout ?? state.stdout,
      stderr: stderr ?? state.stderr,
      error: error ?? state.error,
      executionTime: executionTime ?? state.executionTime,
      memory: memory ?? state.memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }
}

final stdinProvider = StateProvider<String>((ref) => '');
