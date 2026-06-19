import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExecutionState {
  final bool isExecuting;
  final String output;
  final String error;
  final String time;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.output = '',
    this.error = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? output,
    String? error,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      output: output ?? this.output,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  ExecutionState get currentState => state;

  void startExecution() {
    state = state.copyWith(isExecuting: true, output: '', error: '', time: '', memory: '');
  }

  void finishExecution({
    String? output,
    String? error,
    String? time,
    String? memory,
  }) {
    state = state.copyWith(
      isExecuting: false,
      output: output ?? state.output,
      error: error ?? state.error,
      time: time ?? state.time,
      memory: memory ?? state.memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
