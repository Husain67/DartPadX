import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../providers/execution_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/compiler_service.dart';
import '../../models/compiler_preset.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const TopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final isRunning = executionState.isRunning;

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'DartMini',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'beta',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: isRunning ? null : () => _runCode(ref),
            icon: isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow, color: Colors.black),
            label: const Text(
              'Run',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    ref.read(executionProvider.notifier).setRunning(true);

    final settings = ref.read(settingsProvider);
    final useDefault = settings.useDefaultCompiler;

    CompilerPreset? preset;
    if (!useDefault) {
      if (settings.activePresetId != null) {
        preset = settings.presets.firstWhere(
          (p) => p.id == settings.activePresetId,
          orElse: () => throw Exception('Preset not found'),
        );
      }
    }

    final result = await CompilerService.executeCode(
      activeFile.content,
      useDefault,
      preset,
    );

    ref.read(executionProvider.notifier).setOutput(
      stdout: result.stdout,
      stderr: result.stderr,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
