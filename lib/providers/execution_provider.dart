import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';

class ExecutionState {
  final bool isLoading;
  final ExecutionResult? result;

  ExecutionState({this.isLoading = false, this.result});
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setLoadState(bool loading) {
    state = ExecutionState(isLoading: loading, result: state.result);
  }

  void setResult(ExecutionResult res) {
    state = ExecutionState(isLoading: false, result: res);
  }

  void clear() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) => ExecutionNotifier());
