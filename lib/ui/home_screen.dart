import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../data/providers/file_provider.dart';
import '../data/providers/compiler_provider.dart';
import '../data/providers/execution_provider.dart';
import '../services/execution_service.dart';
import 'widgets/toolbar.dart';
import 'widgets/file_tabs.dart';
import 'widgets/editor.dart';
import 'widgets/output_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _runCode(BuildContext context, WidgetRef ref) async {
    // Force save active file content
    ref.read(fileProvider.notifier).forceSave();

    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null || activeFile.content.isEmpty) return;

    ref.read(executionProvider.notifier).setRunning(true);

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.presets.cast().firstWhere(
          (p) => p?.id == compilerState.activePresetId,
          orElse: () => null,
        );

    final result = await ExecutionService.runCode(
      code: activeFile.content,
      useDefault: compilerState.useDefaultOneCompiler,
      customPreset: preset,
    );

    ref.read(executionProvider.notifier).setOutput(
          stdout: result.stdout,
          stderr: result.stderr,
          time: result.time,
          memory: result.memory,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses AppTheme.gradientBackground
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: execState.isRunning ? null : () => _runCode(context, ref),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (execState.isRunning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.play_arrow,
                          color: Colors.black, size: 20),
                    const SizedBox(width: 4),
                    const Text('Run',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
          children: [
            Column(
              children: [
                const IDEToolbar(),
                const FileTabs(),
                const Expanded(child: EditorWidget()),
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }
}
