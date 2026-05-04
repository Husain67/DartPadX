import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
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
  final ApiService _apiService = ApiService();

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode(String code, String stdin) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    final settings = ref.read(settingsProvider);
    final preset = ref.read(settingsProvider.notifier).activePreset;

    try {
      final result = await _apiService.executeCode(
        code: code,
        stdin: stdin,
        useDefault: settings.useDefaultOneCompiler,
        preset: preset,
      );

      state = state.copyWith(
        isExecuting: false,
        stdout: result['stdout']?.toString() ?? '',
        stderr: result['stderr']?.toString() ?? '',
        error: result['error']?.toString() ?? '',
        executionTime: result['executionTime']?.toString() ?? '',
        memory: result['memory']?.toString() ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
      );
    }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
