import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/api_service.dart';
import 'compiler_provider.dart';
import 'file_provider.dart';

class ExecutionState {
  final bool isExecuting;
  final ExecutionResult? result;
  final String stdin;
  final bool showOutput;

  ExecutionState({
    required this.isExecuting,
    this.result,
    required this.stdin,
    this.showOutput = false,
  });

  ExecutionState copyWith({
    bool? isExecuting,
    ExecutionResult? result,
    String? stdin,
    bool? showOutput,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      result: result ?? this.result,
      stdin: stdin ?? this.stdin,
      showOutput: showOutput ?? this.showOutput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState(isExecuting: false, stdin: ''));

  void setStdin(String val) {
    state = state.copyWith(stdin: val);
  }

  void toggleOutput(bool show) {
    state = state.copyWith(showOutput: show);
  }

  void clearOutput() {
    state = state.copyWith(result: ExecutionResult.empty());
  }

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider);
    final compilerState = ref.read(compilerProvider);

    final activeFile = fileState.activeFile;
    if (activeFile == null || activeFile.content.isEmpty) return;

    state = state.copyWith(isExecuting: true, showOutput: true);

    ExecutionResult result;
    if (compilerState.useDefaultCompiler || compilerState.activePreset == null) {
      result = await ApiService.executeDefault(activeFile.content, state.stdin);
    } else {
      result = await ApiService.executeWithPreset(compilerState.activePreset!, activeFile.content, state.stdin);
    }

    state = state.copyWith(isExecuting: false, result: result);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
