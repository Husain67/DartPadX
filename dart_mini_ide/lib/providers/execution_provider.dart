import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';

import 'compiler_provider.dart';

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
  final ExecutionService _service;
  final Ref _ref;

  ExecutionNotifier(this._service, this._ref) : super(ExecutionState());

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, result: null);

    final compilerState = _ref.read(compilerProvider);
    final activePreset = _ref.read(compilerProvider.notifier).activePreset;

    ExecutionResult res;
    if (compilerState.useDefaultOneCompiler || activePreset == null) {
      res = await _service.executeDefault(code, stdin: stdin);
    } else {
      res = await _service.executeCustom(code, activePreset, stdin: stdin);
    }

    state = state.copyWith(isRunning: false, result: res);
  }

  void clearOutput() {
    state = ExecutionState(isRunning: false, result: null);
  }
}

final executionServiceProvider = Provider((ref) => ExecutionService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref.read(executionServiceProvider), ref);
});
