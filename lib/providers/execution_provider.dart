import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning(bool running) {
    state = state.copyWith(isRunning: running);
  }

  void setOutput({
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    state = state.copyWith(
      stdout: stdout ?? state.stdout,
      stderr: stderr ?? state.stderr,
      time: time ?? state.time,
      memory: memory ?? state.memory,
      isRunning: false,
    );
  }

  void clear() {
      state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
