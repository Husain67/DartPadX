import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/execution_result.dart';
import '../services/execution_service.dart';
import 'settings_provider.dart';

class ExecutionState {
  final bool isLoading;
  final ExecutionResult? result;
  final String? error;

  ExecutionState({
    this.isLoading = false,
    this.result,
    this.error,
  });
}

final executionServiceProvider = Provider((ref) => ExecutionService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final executionService = ref.read(executionServiceProvider);
  return ExecutionNotifier(executionService, ref);
});

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final ExecutionService _executionService;
  final Ref _ref;

  ExecutionNotifier(this._executionService, this._ref) : super(ExecutionState());

  Future<void> execute(String code, String stdin) async {
    state = ExecutionState(isLoading: true);

    try {
      final settings = _ref.read(settingsProvider);

      ExecutionResult result;
      if (settings.useCustomPreset) {
        final preset = settings.activePreset;
        if (preset != null) {
          result = await _executionService.executeCustom(preset, code, stdin);
        } else {
           result = ExecutionResult(error: "No active preset selected.", isSuccess: false);
        }
      } else {
        result = await _executionService.executeOneCompiler(code, stdin);
      }

      state = ExecutionState(
        isLoading: false,
        result: result,
      );
    } catch (e) {
      state = ExecutionState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}
