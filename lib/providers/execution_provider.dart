import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';
import 'file_provider.dart';
import 'compiler_provider.dart';

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionState {
  final bool isRunning;
  final ExecutionResult? result;

  ExecutionState({this.isRunning = false, this.result});

  ExecutionState copyWith({bool? isRunning, ExecutionResult? result}) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      result: result ?? this.result,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> runCode() async {
    final fileState = ref.read(fileProvider);
    final compilerState = ref.read(compilerProvider);
    final stdin = ref.read(stdinProvider);

    final activeFile = fileState.activeFile;
    final activePreset = compilerState.activePreset;

    if (activeFile == null || activePreset == null) return;

    state = state.copyWith(isRunning: true, result: null);

    try {
      final result = await CompilerService.executeCode(
        preset: activePreset,
        code: activeFile.content,
        stdin: stdin,
        language: 'dart',
      );
      state = state.copyWith(isRunning: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        result: ExecutionResult(
          stdout: '',
          stderr: '',
          error: e.toString(),
          executionTime: '',
          memory: '',
        ),
      );
    }
  }

  void clearOutput() {
    state = ExecutionState(isRunning: false, result: null);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
