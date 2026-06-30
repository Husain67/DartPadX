import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/output_provider.dart';
import '../providers/preset_provider.dart';
import '../services/compiler_service.dart';
import '../theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final outputState = ref.watch(outputProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Uses AppTheme.backgroundGradient on Container
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
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: outputState.isRunning ? null : () => _runCode(ref),
              icon: outputState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            const IdeToolbar(),
            _buildFileTabs(context, ref, fileState),
            const Expanded(
              child: Stack(
                children: [
                  CodeEditorWidget(),
                  OutputSheetWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTabs(BuildContext context, WidgetRef ref, FileState fileState) {
    if (fileState.files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: AppTheme.appBarColor.withValues(alpha: 0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? Colors.white10 : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (fileState.files.length > 1 || file.name != 'main.dart') {
                        // Switch to another file before deleting if possible
                        if (isActive) {
                           ref.read(fileProvider.notifier).deleteActiveFile();
                        } else {
                           // Implementation for deleting non-active file could be added
                           ref.read(fileProvider.notifier).switchFile(file.id);
                           ref.read(fileProvider.notifier).deleteActiveFile();
                        }
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    ref.read(outputProvider.notifier).startExecution();

    final presetState = ref.read(presetProvider);
    final result = await CompilerService.executeCode(activeFile.content, presetState);

    ref.read(outputProvider.notifier).completeExecution(
      stdout: result['stdout'] ?? '',
      stderr: result['stderr'] ?? '',
      executionTime: result['executionTime'] ?? '',
      memory: result['memory'] ?? '',
    );
  }
}
