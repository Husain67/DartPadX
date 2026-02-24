import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/execution_service.dart';
import 'settings_provider.dart';

final executionServiceProvider = Provider<ExecutionService>((ref) {
  return ExecutionService();
});

final executionResultProvider = StateProvider<ExecutionResponse?>((ref) => null);
final executionLoadingProvider = StateProvider<bool>((ref) => false);

class ExecutionController {
  final Ref ref;

  ExecutionController(this.ref);

  Future<void> runCode(String code, {String stdin = ''}) async {
    final settings = ref.read(settingsProvider);
    final service = ref.read(executionServiceProvider);

    ref.read(executionLoadingProvider.notifier).state = true;
    ref.read(executionResultProvider.notifier).state = null;

    ExecutionResponse result;

    try {
      if (settings.useOneCompiler) {
        result = await service.runOneCompiler(code, stdin);
      } else {
        if (settings.selectedPresetId == null) {
           result = ExecutionResponse(error: 'No custom preset selected. Please select one in Settings.');
        } else {
           final preset = settings.presets.firstWhere(
             (p) => p.id == settings.selectedPresetId,
             orElse: () => throw Exception('Selected preset not found'),
           );
           result = await service.runCustomPreset(preset, code, stdin);
        }
      }
    } catch (e) {
      result = ExecutionResponse(error: 'Execution Error: $e');
    }

    ref.read(executionResultProvider.notifier).state = result;
    ref.read(executionLoadingProvider.notifier).state = false;
  }
}

final executionControllerProvider = Provider<ExecutionController>((ref) {
  return ExecutionController(ref);
});
