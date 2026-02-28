import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'settings_provider.dart';
import 'file_provider.dart';

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
  final Ref _ref;
  final ApiService _apiService = ApiService();

  ExecutionNotifier(this._ref) : super(ExecutionState());

  Future<void> runCode() async {
    final activeFile = _ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) {
      state = state.copyWith(stderr: 'No code to run.');
      return;
    }

    state = state.copyWith(
      isRunning: true,
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );

    final preset = _ref.read(settingsProvider).activePreset;

    final result = await _apiService.executeCode(activeFile.content, preset);

    state = state.copyWith(
      isRunning: false,
      stdout: result.stdout,
      stderr: result.error.isNotEmpty ? result.error : result.stderr,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  void clearOutput() {
    state = state.copyWith(
      stdout: '',
      stderr: '',
      executionTime: '',
      memory: '',
    );
  }
}
