import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'file_provider.dart';
import 'compiler_provider.dart';

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
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
  final ApiService _apiService;
  final Ref _ref;

  ExecutionNotifier(this._apiService, this._ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode() async {
    final currentFile = _ref.read(fileProvider.notifier).currentFile;
    final currentPreset = _ref.read(compilerProvider.notifier).currentPreset;

    if (currentFile == null || currentPreset == null) {
      state = state.copyWith(stderr: 'Error: No file or preset selected.');
      return;
    }

    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final result = await _apiService.executeCode(currentFile.content, currentPreset);
      state = state.copyWith(
        isRunning: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        executionTime: result['executionTime'] ?? '',
        memory: result['memory'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution failed: $e',
      );
    }
  }
}

final apiServiceProvider = Provider((ref) => ApiService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExecutionNotifier(apiService, ref);
});
