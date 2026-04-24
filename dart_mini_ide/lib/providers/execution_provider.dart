import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
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

  void setOutput({
    required String stdout,
    required String stderr,
    required String executionTime,
    required String memory,
  }) {
    state = state.copyWith(
      stdout: stdout,
      stderr: stderr,
      executionTime: executionTime,
      memory: memory,
      isExecuting: false,
    );
  }

  void clearOutput() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final useDefaultOneCompilerProvider = StateProvider<bool>((ref) => true);
