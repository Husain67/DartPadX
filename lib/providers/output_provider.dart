import 'package:flutter_riverpod/flutter_riverpod.dart';

class OutputState {
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;
  final bool isRunning;
  final bool showSheet;

  OutputState({
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
    this.isRunning = false,
    this.showSheet = false,
  });

  OutputState copyWith({
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
    bool? isRunning,
    bool? showSheet,
  }) {
    return OutputState(
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      isRunning: isRunning ?? this.isRunning,
      showSheet: showSheet ?? this.showSheet,
    );
  }
}

class OutputNotifier extends StateNotifier<OutputState> {
  OutputNotifier() : super(OutputState());

  OutputState get currentState => state;

  void startExecution() {
    state = state.copyWith(isRunning: true, showSheet: true, stdout: '', stderr: '', executionTime: '', memory: '');
  }

  void completeExecution({
    required String stdout,
    String stderr = '',
    String executionTime = '',
    String memory = '',
  }) {
    state = state.copyWith(
      isRunning: false,
      stdout: stdout,
      stderr: stderr,
      executionTime: executionTime,
      memory: memory,
    );
  }

  void setError(String error) {
    state = state.copyWith(
      isRunning: false,
      stderr: error,
      showSheet: true,
    );
  }

  void toggleSheet(bool show) {
    state = state.copyWith(showSheet: show);
  }

  void clear() {
    state = OutputState(showSheet: state.showSheet);
  }
}

final outputProvider = StateNotifierProvider<OutputNotifier, OutputState>((ref) {
  return OutputNotifier();
});
