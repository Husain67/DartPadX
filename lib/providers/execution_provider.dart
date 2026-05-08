import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/compiler_service.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

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

final stdinProvider = StateProvider<String>((ref) => '');

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> runCode() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final stdinStr = ref.read(stdinProvider);
    final settingsState = ref.read(settingsProvider);

    state = state.copyWith(isExecuting: true);

    ExecutionResult result;
    if (settingsState.useDefaultOneCompiler || settingsState.activePreset == null) {
      result = await CompilerService.executeDefault(activeFile.content, stdinStr);
    } else {
      result = await CompilerService.executeCustom(settingsState.activePreset!, activeFile.content, stdinStr);
    }

    state = state.copyWith(isExecuting: false, result: result);
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) => ExecutionNotifier(ref));
