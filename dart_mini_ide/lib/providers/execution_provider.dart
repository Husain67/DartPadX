import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import 'file_provider.dart';
import 'preset_provider.dart';
import 'settings_provider.dart';

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

  Future<void> executeCode() async {
    final fileState = ref.read(fileProvider);
    final code = fileState.activeFile?.content;
    if (code == null || code.isEmpty) return;

    state = state.copyWith(isRunning: true, result: null);

    final settings = ref.read(settingsProvider);
    ExecutionResult result;

    if (settings.useDefaultOneCompiler) {
      result = await ExecutionService.executeDefaultOneCompiler(code);
    } else {
      final presets = ref.read(presetProvider);
      final activePreset = presets.firstWhere(
        (p) => p.id == settings.activePresetId,
        orElse: () => presets.first,
      );
      result = await ExecutionService.executeCustomPreset(code, activePreset);
    }

    state = state.copyWith(isRunning: false, result: result);
  }

  void clearOutput() {
    state = ExecutionState(isRunning: false, result: null);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
