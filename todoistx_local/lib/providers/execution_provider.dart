import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import 'settings_provider.dart';
import 'file_provider.dart';

final executionProvider =
    StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isExecuting;
  final String? stdout;
  final String? stderr;
  final String? error;
  final String? time;
  final String? memory;
  final bool showOutput;

  ExecutionState({
    this.isExecuting = false,
    this.stdout,
    this.stderr,
    this.error,
    this.time,
    this.memory,
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? time,
    String? memory,
    bool? showOutput,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      showOutput: showOutput ?? this.showOutput,
    );
  }

  void clear() {
    // no-op, managed by notifier
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    final activePreset = ref.read(settingsProvider.notifier).activePreset;
    if (activePreset == null) {
      state = state.copyWith(
          isExecuting: false,
          error: "No compiler preset selected.",
          showOutput: true);
      return;
    }

    state = state.copyWith(
        isExecuting: true,
        showOutput: true,
        stdout: null,
        stderr: null,
        error: null,
        time: null,
        memory: null);

    try {
      final result = await ExecutionService.execute(
        code: activeFile.content,
        preset: activePreset,
        stdin: '', // Add stdin support if needed later from UI
      );

      state = state.copyWith(
        isExecuting: false,
        stdout: result['stdout'],
        stderr: result['stderr'],
        error: result['error'],
        time: result['time'],
        memory: result['memory'],
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

  void toggleOutput() {
    state = state.copyWith(showOutput: !state.showOutput);
  }
}
