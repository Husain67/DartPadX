import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: execState.isExecuting ? null : () => ref.read(executionProvider.notifier).executeCode(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    if (execState.isExecuting)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    else
                      const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                    const SizedBox(width: 4),
                    const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildFileTabs(context, ref, fileState),
                const EditorToolbar(),
                const Expanded(child: CodeEditorWidget()),
                const SizedBox(height: 60), // Space for output handle
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTabs(BuildContext context, WidgetRef ref, FileState fileState) {
    return Container(
      height: 40,
      color: const Color(0xFF111111),
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
                color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  file.name,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
