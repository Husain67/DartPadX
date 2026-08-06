import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import 'editor_provider.dart';
import 'settings_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool showOutput;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
    bool? showOutput,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      showOutput: showOutput ?? this.showOutput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> runCode() async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    final preset = ref.read(settingsProvider).activePreset;

    state = state.copyWith(isRunning: true, showOutput: true, stdout: '', stderr: '', time: '', memory: '');

    try {
      final result = await ExecutionService.execute(
        code: activeFile.content,
        preset: preset,
      );

      state = state.copyWith(
        isRunning: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        time: result['time'] ?? '',
        memory: result['memory'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution Error: $e',
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

  void hideOutput() {
    state = state.copyWith(showOutput: false);
  }
}
