import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../utils/api_client.dart';

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String time;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> runCode(CompilerPreset preset, String code) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', time: '', memory: '');

    try {
      final result = await ApiClient.executeCode(preset: preset, code: code);

      if (result.containsKey('error')) {
        state = state.copyWith(
          isRunning: false,
          stderr: result['error'].toString(),
        );
        return;
      }

      final body = result['body'];
      if (body == null) {
        state = state.copyWith(
          isRunning: false,
          stderr: 'Empty response body.',
        );
        return;
      }

      String stdout = ApiClient.extractFromPath(body, preset.resultPaths['stdout'] ?? '');
      String stderr = ApiClient.extractFromPath(body, preset.resultPaths['stderr'] ?? '');
      String err = ApiClient.extractFromPath(body, preset.resultPaths['error'] ?? '');
      String time = ApiClient.extractFromPath(body, preset.resultPaths['executionTime'] ?? '');
      String memory = ApiClient.extractFromPath(body, preset.resultPaths['memory'] ?? '');

      if (stderr.isEmpty && err.isNotEmpty) {
        stderr = err;
      }

      // Some APIs return stdout even if there is stderr.
      if (stdout.isEmpty && stderr.isEmpty && body is Map && !preset.resultPaths.values.any((v) => v.isNotEmpty)) {
        // Fallback to raw string if parsing fails or no paths given and not standard map
        stdout = body.toString();
      }

      state = state.copyWith(
        isRunning: false,
        stdout: stdout,
        stderr: stderr,
        time: time,
        memory: memory,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: 'Execution failed: \$e',
      );
    }
  }
}
