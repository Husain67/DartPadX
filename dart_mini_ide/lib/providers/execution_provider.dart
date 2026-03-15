import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;
  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isLoading: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    final preset = ref.read(activeCompilerPresetProvider);
    final service = ExecutionService();

    final result = await service.executeCode(
      code: code,
      stdin: stdin,
      preset: preset,
    );

    state = state.copyWith(
      isLoading: false,
      stdout: result.stdout,
      stderr: result.stderr,
      error: result.error,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
