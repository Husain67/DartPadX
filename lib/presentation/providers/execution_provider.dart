import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/execution_service.dart';
import 'file_provider.dart';
import 'compiler_provider.dart';

class ExecutionState {
  final bool isExecuting;
  final ExecutionResult? result;

  ExecutionState({this.isExecuting = false, this.result});

  ExecutionState copyWith({bool? isExecuting, ExecutionResult? result}) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      result: result ?? this.result,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode(String stdinStr) async {
    state = state.copyWith(isExecuting: true);

    final fileState = ref.read(fileProvider);
    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first
    );

    final compilerState = ref.read(compilerProvider);

    ExecutionResult result;
    if (compilerState.activePresetId == null) {
      result = await ExecutionService.executeDefault(
        code: activeFile.content,
        stdin: stdinStr,
      );
    } else {
      final preset = compilerState.presets.firstWhere((p) => p.id == compilerState.activePresetId);
      result = await ExecutionService.executeCustom(
        preset: preset,
        code: activeFile.content,
        stdin: stdinStr,
      );
    }

    state = state.copyWith(isExecuting: false, result: result);
  }

  void clearOutput() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});

final stdinProvider = StateProvider<String>((ref) => '');
