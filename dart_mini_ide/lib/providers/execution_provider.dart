import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    required this.isRunning,
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
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState(isRunning: false));

  Future<void> executeCode(String code) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    try {
      final apiService = ApiService(ref);
      final result = await apiService.execute(code);

      state = state.copyWith(
        isRunning: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        executionTime: result['executionTime']?.toString() ?? '',
        memory: result['memory']?.toString() ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: $e',
      );
    }
  }

  void clearOutput() {
    state = ExecutionState(isRunning: false);
  }
}
