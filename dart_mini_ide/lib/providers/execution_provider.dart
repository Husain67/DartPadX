import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/services/compiler_service.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

class ExecutionState {
  final bool isRunning;
  final ExecutionResult? result;
  final String stdinInput;

  ExecutionState({this.isRunning = false, this.result, this.stdinInput = ''});
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void setStdin(String input) {
    state = ExecutionState(
      isRunning: state.isRunning,
      result: state.result,
      stdinInput: input,
    );
  }

  Future<void> runCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) return;

    final settings = ref.read(settingsProvider);
    final preset = settings.activePreset;

    if (preset == null) return;

    state = ExecutionState(isRunning: true, stdinInput: state.stdinInput);

    final result = await CompilerService.executeCode(activeFile.content, state.stdinInput, preset);

    state = ExecutionState(isRunning: false, result: result, stdinInput: state.stdinInput);
  }

  void clearOutput() {
    state = ExecutionState(isRunning: false, stdinInput: state.stdinInput);
  }
}
