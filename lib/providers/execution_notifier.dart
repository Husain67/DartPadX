import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool isPanelOpen;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
    this.isPanelOpen = false,
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
    bool? isPanelOpen,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning() {
    state = state.copyWith(
      isLoading: true,
      isPanelOpen: true,
      stdout: '',
      stderr: '',
      time: '',
      memory: '',
    );
  }

  void setResult({
    required String stdout,
    required String stderr,
    required String time,
    required String memory,
  }) {
    state = state.copyWith(
      isLoading: false,
      stdout: stdout,
      stderr: stderr,
      time: time,
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
      time: '',
      memory: '',
    );
  }

  void togglePanel() {
    state = state.copyWith(isPanelOpen: !state.isPanelOpen);
  }

  void setPanelState(bool isOpen) {
    state = state.copyWith(isPanelOpen: isOpen);
  }
}
