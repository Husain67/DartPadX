import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(
    ref.read(apiServiceProvider),
    ref,
  );
});

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;
  final bool hasRun;

  ExecutionState({
    required this.isExecuting,
    required this.stdout,
    required this.stderr,
    required this.time,
    required this.memory,
    required this.hasRun,
  });

  factory ExecutionState.initial() {
    return ExecutionState(
      isExecuting: false,
      stdout: '',
      stderr: '',
      time: '-',
      memory: '-',
      hasRun: false,
    );
  }

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
    bool? hasRun,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
      hasRun: hasRun ?? this.hasRun,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final ApiService _apiService;
  final Ref _ref;

  ExecutionNotifier(this._apiService, this._ref) : super(ExecutionState.initial());

  Future<void> runCode() async {
    final activeFile = _ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.trim().isEmpty) {
      state = state.copyWith(
        isExecuting: false,
        stdout: '',
        stderr: 'Error: No code to execute.',
        hasRun: true,
      );
      return;
    }

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', hasRun: true);

    final settings = _ref.read(settingsProvider);

    ExecutionResult result;
    if (settings.useDefaultOneCompiler) {
      result = await _apiService.executeOneCompiler(activeFile.content);
    } else {
      final preset = settings.selectedPreset;
      if (preset == null) {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'Error: No custom compiler preset selected.',
        );
        return;
      }
      result = await _apiService.executeCustomAPI(activeFile.content, preset);
    }

    state = state.copyWith(
      isExecuting: false,
      stdout: result.stdout,
      stderr: result.stderr,
      time: result.executionTime,
      memory: result.memory,
    );
  }

  void clearOutput() {
    state = ExecutionState.initial();
  }
}
