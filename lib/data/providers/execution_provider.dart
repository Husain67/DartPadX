import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider =
    StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool showSheet;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
    this.showSheet = false,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
    bool? showSheet,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      showSheet: showSheet ?? this.showSheet,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning(bool running) {
    state = state.copyWith(isRunning: running, showSheet: true);
  }

  void setOutput(
      {String stdout = '',
      String stderr = '',
      String time = '',
      String memory = ''}) {
    state = state.copyWith(
      isRunning: false,
      stdout: stdout,
      stderr: stderr,
      time: time,
      memory: memory,
      showSheet: true,
    );
  }

  void clearOutput() {
    state = state.copyWith(
      stdout: '',
      stderr: '',
      time: '',
      memory: '',
    );
  }

  void closeSheet() {
    state = state.copyWith(showSheet: false);
  }
}
