import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';
import 'settings_provider.dart';

final compilerServiceProvider = Provider((ref) => CompilerService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String? error;
  final int executionTime;
  final int memory;

  const ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error,
    this.executionTime = 0,
    this.memory = 0,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    int? executionTime,
    int? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(const ExecutionState());

  Future<void> runCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', error: null);

    try {
      final preset = ref.read(settingsProvider);
      final service = ref.read(compilerServiceProvider);

      final result = await service.executeCode(
        preset,
        code,
        stdin: stdin,
      );

      state = state.copyWith(
        isRunning: false,
        stdout: result['stdout'] as String,
        stderr: result['stderr'] as String,
        error: result['error'] as String?,
        executionTime: result['executionTime'] as int,
        memory: result['memory'] as int,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        error: e.toString(),
      );
    }
  }

  void clearOutput() {
    state = const ExecutionState();
  }
}
