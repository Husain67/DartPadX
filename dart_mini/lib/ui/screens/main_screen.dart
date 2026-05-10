import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../core/theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

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
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting
                  ? null
                  : () {
                      final activeFile = ref.read(fileProvider).activeFile;
                      if (activeFile != null) {
                         ref.read(executionProvider.notifier).executeCode(activeFile.content);
                      }
                    },
              icon: execState.isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const EditorToolbar(),
              // File Tabs
              if (fileState.files.isNotEmpty)
                Container(
                  height: 40,
                  color: AppTheme.backgroundColor2,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fileState.files.length,
                    itemBuilder: (context, index) {
                      final file = fileState.files[index];
                      final isActive = file.id == fileState.activeFileId;
                      return GestureDetector(
                        onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.backgroundColor1 : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                file.name,
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.white54,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                                child: const Icon(Icons.close, size: 14, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
}
