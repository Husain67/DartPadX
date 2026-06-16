import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning(bool running) {
    state = state.copyWith(isRunning: running);
  }

  void setOutput({String? stdout, String? stderr, String? executionTime, String? memory}) {
    state = state.copyWith(
      isRunning: false,
      stdout: stdout ?? state.stdout,
      stderr: stderr ?? state.stderr,
      executionTime: executionTime ?? state.executionTime,
      memory: memory ?? state.memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }
}

final stdinProvider = StateProvider<String>((ref) => '');
