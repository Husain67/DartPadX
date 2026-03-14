import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../utils/api_service.dart';

class ExecutionState {
  final bool isLoading;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionState({
    this.isLoading = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isLoading,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isLoading: isLoading ?? this.isLoading,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  Future<void> executeCode(String code, {bool useOneCompiler = true, CompilerPreset? preset}) async {
    state = state.copyWith(isLoading: true, stdout: '', stderr: '', time: '', memory: '');
    try {
      final result = useOneCompiler
          ? await ApiService.executeOneCompiler(code)
          : await ApiService.executeCustom(code, preset!);

      state = state.copyWith(
        isLoading: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        time: result['time'] ?? '',
        memory: result['memory'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        stderr: 'Error: ${e.toString()}',
      );
    }
  }

  void clearOutput() {
    state = state.copyWith(
      stdout: '',
      stderr: '',
      time: '',
      memory: '',
    );
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
