import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String metrics;
  final bool showOutput;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.metrics = '',
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? metrics,
    bool? showOutput,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      metrics: metrics ?? this.metrics,
      showOutput: showOutput ?? this.showOutput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final CompilerService _compilerService = CompilerService();

  ExecutionNotifier() : super(ExecutionState());

  void executeCode(String code, dynamic preset, {String stdin = ''}) async {
    state = state.copyWith(isExecuting: true, showOutput: true, stdout: '', stderr: '', metrics: '');
    try {
      final result = await _compilerService.executeCode(code, preset, stdin: stdin);
      state = state.copyWith(
        isExecuting: false,
        stdout: result.stdout,
        stderr: result.stderr,
        metrics: '${result.time.isNotEmpty ? "Time: ${result.time}" : ""} ${result.memory.isNotEmpty ? "Memory: ${result.memory}" : ""}'.trim(),
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Critical Execution Error: $e',
      );
    }
  }

  void clearOutput() {
    state = state.copyWith(stdout: '', stderr: '', metrics: '', showOutput: false);
  }
}
