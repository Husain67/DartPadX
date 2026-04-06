import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              onPressed: isExecuting ? null : () {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  ref.read(executionProvider.notifier).executeCode(activeFile.content);
                }
              },
              icon: isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Stack(
          children: [
            Column(
              children: [
                const EditorToolbar(),
                const Expanded(child: CodeEditorWidget()),
                const SizedBox(height: 50), // Buffer for the output sheet handle
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }
}
