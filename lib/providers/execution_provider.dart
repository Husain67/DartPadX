import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
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

  void setRunning(bool isRunning) {
    state = state.copyWith(isRunning: isRunning);
  }

  void setResult({
    required String stdout,
    required String stderr,
    required String error,
    required String executionTime,
    required String memory,
  }) {
    state = state.copyWith(
      isRunning: false,
      stdout: stdout,
      stderr: stderr,
      error: error,
      executionTime: executionTime,
      memory: memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }
}

final stdinProvider = StateProvider<String>((ref) => '');
