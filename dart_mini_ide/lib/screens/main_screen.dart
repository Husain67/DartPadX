import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: execState.isLoading ? null : () => _runCode(ref),
              icon: execState.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const ToolbarWidget(),
                const Expanded(child: EditorWidget()),
              ],
            ),
            if (execState.sheetVisible)
              const OutputSheet(),
          ],
        ),
      ),
    );
  }

  Future<void> _runCode(WidgetRef ref) async {
    final fileState = ref.read(fileProvider);
    final currentFile = fileState.activeFile;
    if (currentFile == null) return;

    ref.read(executionProvider.notifier).setRunning();

    final settings = ref.read(settingsProvider);
    final result = await ApiService.executeCode(
      code: currentFile.content,
      useDefault: settings.useDefaultOneCompiler,
      preset: settings.activePreset,
    );

    ref.read(executionProvider.notifier).setOutput(
      stdout: result['stdout'] ?? '',
      stderr: result['stderr'] ?? '',
      time: result['time'] ?? '',
      memory: result['memory'] ?? '',
    );
  }
}
