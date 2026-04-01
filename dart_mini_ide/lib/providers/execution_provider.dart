import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;
  final String stdinInput;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
    this.stdinInput = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    String? stdinInput,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      stdinInput: stdinInput ?? this.stdinInput,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ExecutionNotifier(this._apiClient, this._ref) : super(ExecutionState());

  Future<void> executeCode() async {
    final activeFile = _ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final preset = _ref.read(settingsProvider).activePreset;

    // Explicitly force save current contents to hive before sending to execution
    _ref.read(fileProvider.notifier).forceSaveCurrent(activeFile.content);

    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', error: '', executionTime: '', memory: '');

    try {
      final result = await _apiClient.executeCode(
        code: activeFile.content,
        preset: preset,
        stdinInput: state.stdinInput,
      );

      state = state.copyWith(
        isExecuting: false,
        stdout: result['stdout'] ?? '',
        stderr: result['stderr'] ?? '',
        error: result['error'] ?? '',
        executionTime: result['executionTime'] ?? '',
        memory: result['memory'] ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        error: e.toString(),
      );
    }
  }

  void clearOutput() {
     state = state.copyWith(stdout: '', stderr: '', error: '', executionTime: '', memory: '');
  }

  void setStdin(String input) {
    state = state.copyWith(stdinInput: input);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExecutionNotifier(apiClient, ref);
});