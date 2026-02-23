import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/models/execution_result.dart';
import 'package:dart_mini_ide/services/execution_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final executionServiceProvider = Provider<ExecutionService>((ref) => ExecutionService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final service = ref.watch(executionServiceProvider);
  return ExecutionNotifier(service);
});

class ExecutionState {
  final ExecutionResult? result;
  final bool isExecuting;
  final bool outputVisible;

  ExecutionState({
    this.result,
    this.isExecuting = false,
    this.outputVisible = false,
  });

  ExecutionState copyWith({
    ExecutionResult? result,
    bool? isExecuting,
    bool? outputVisible,
  }) {
    return ExecutionState(
      result: result ?? this.result,
      isExecuting: isExecuting ?? this.isExecuting,
      outputVisible: outputVisible ?? this.outputVisible,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final ExecutionService _service;

  ExecutionNotifier(this._service) : super(ExecutionState());

  Future<void> execute(CodeFile file, String stdin, {CompilerPreset? preset}) async {
    state = state.copyWith(isExecuting: true, outputVisible: true);

    final result = await _service.executeCode(
      file: file,
      stdin: stdin,
      preset: preset,
    );

    state = state.copyWith(
      result: result,
      isExecuting: false,
    );
  }

  void toggleOutput(bool visible) {
    state = state.copyWith(outputVisible: visible);
  }

  void clearOutput() {
    state = ExecutionState(outputVisible: false);
  }
}
