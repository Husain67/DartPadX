import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

class ExecutionState {
  final bool isExecuting;
  final ExecutionResult? result;

  ExecutionState({this.isExecuting = false, this.result});
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;
  final ExecutionService _service = ExecutionService();

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> runCode(String stdin) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final settings = ref.read(settingsProvider);
    final useDefault = settings.useDefaultCompiler;

    final activePresetId = settings.activePresetId;
    final preset = settings.presets.cast<dynamic>().firstWhere(
      (p) => p.id == activePresetId,
      orElse: () => null,
    );

    state = ExecutionState(isExecuting: true);

    try {
      final result = await _service.executeCode(
        code: activeFile.content,
        stdin: stdin,
        useDefault: useDefault,
        preset: preset,
      );
      state = ExecutionState(isExecuting: false, result: result);
    } catch (e) {
      state = ExecutionState(
        isExecuting: false,
        result: ExecutionResult(stdout: '', stderr: 'Execution failed: $e', executionTime: '', memory: ''),
      );
    }
  }

  void clearOutput() {
    state = ExecutionState(isExecuting: false, result: null);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
