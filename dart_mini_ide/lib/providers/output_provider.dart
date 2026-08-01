import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';

final outputProvider = StateNotifierProvider<OutputNotifier, OutputState>((ref) {
  return OutputNotifier();
});

class OutputState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final bool isVisible;

  OutputState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.isVisible = false,
  });

  OutputState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    bool? isVisible,
  }) {
    return OutputState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class OutputNotifier extends StateNotifier<OutputState> {
  OutputNotifier() : super(OutputState());

  void setOutput(CompilerOutput output) {
    state = state.copyWith(
      isLoading: false,
      stdout: output.stdout,
      stderr: output.stderr,
      error: output.error,
      executionTime: output.executionTime,
      memory: output.memory,
      isVisible: true,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading, isVisible: true);
  }

  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  void show() {
     state = state.copyWith(isVisible: true);
  }

  void clear() {
    state = OutputState();
  }
}
