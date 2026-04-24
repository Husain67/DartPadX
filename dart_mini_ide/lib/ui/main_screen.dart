import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/preset_provider.dart';
import '../services/execution_service.dart';
import 'code_editor.dart';
import 'toolbar.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFACC15), width: 1),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Color(0xFFFACC15),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: isExecuting ? null : () => _runCode(ref),
              icon: isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
              label: const Text(
                'Run',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const EditorToolbar(),
              const Expanded(
                child: CodeEditorWidget(),
              ),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Future<void> _runCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    ref.read(executionProvider.notifier).setExecuting(true);

    final useDefault = ref.read(useDefaultOneCompilerProvider);
    final selectedPreset = ref.read(selectedPresetProvider);

    final result = await ExecutionService.execute(
      code: activeFile.content,
      stdin: '', // Input feature can be expanded later if needed
      useDefaultOneCompiler: useDefault,
      customPreset: selectedPreset,
    );

    ref.read(executionProvider.notifier).setOutput(
      stdout: result['stdout'] ?? '',
      stderr: result['stderr'] ?? '',
      executionTime: result['executionTime'] ?? '',
      memory: result['memory'] ?? '',
    );
  }
}
