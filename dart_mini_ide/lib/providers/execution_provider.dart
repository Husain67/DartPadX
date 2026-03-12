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
  final bool showOutput;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    bool? showOutput,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      showOutput: showOutput ?? this.showOutput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning(bool isRunning) {
    state = state.copyWith(isRunning: isRunning, showOutput: true);
  }

  void setOutput({
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    state = state.copyWith(
      stdout: stdout,
      stderr: stderr,
      executionTime: executionTime,
      memory: memory,
      isRunning: false,
      showOutput: true,
    );
  }

  void clearOutput() {
    state = ExecutionState();
  }

  void hideOutput() {
    state = state.copyWith(showOutput: false);
  }
}
