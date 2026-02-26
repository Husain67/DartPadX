import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class ExecutionState {
  final bool isLoading;
  final ExecutionResult? result;

  ExecutionState({this.isLoading = false, this.result});
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final CompilerService _service;

  ExecutionNotifier(this._service) : super(ExecutionState());

  Future<void> execute(CodeFile file, CompilerPreset preset) async {
    state = ExecutionState(isLoading: true, result: null); // Clear previous result while loading? Or keep it? Usually clear or keep. Let's clear to show fresh state.

    final result = await _service.execute(file, preset);

    state = ExecutionState(isLoading: false, result: result);
  }

  void clear() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(CompilerService());
});
