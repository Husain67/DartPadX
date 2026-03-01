import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import '../models/compiler_preset.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isExecuting;
  final ExecutionResult? result;

  ExecutionState({this.isExecuting = false, this.result});
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  Future<void> executeCode(String code, CompilerPreset? preset) async {
    state = ExecutionState(isExecuting: true);
    final result = await ExecutionService.executeCode(code, preset);
    state = ExecutionState(isExecuting: false, result: result);
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
