import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor.dart';
import '../widgets/output_sheet.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
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
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: ref.watch(executionProvider).isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: ref.watch(executionProvider).isRunning ? null : () => ref.read(executionProvider.notifier).runCode(),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const AppToolbar(),
              _buildFileTabs(ref),
              const Expanded(child: CodeEditorWidget()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Widget _buildFileTabs(WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    return Container(
      height: 40,
      color: const Color(0xFF121212),
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
                color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Row(
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                           onTap: () => ref.read(fileProvider.notifier).deleteActiveFile(),
                           child: const Icon(Icons.close, size: 14, color: Colors.white54),
                        ),
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
