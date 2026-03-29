import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../core/constants.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor.dart';
import '../widgets/output_sheet.dart';
import '../../providers/execution_provider.dart';
import '../../providers/file_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppConstants.bgColorStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                final activeFile = ref.read(fileProvider.notifier).activeFile;
                if (activeFile != null) {
                  ref.read(executionProvider.notifier).executeCode(activeFile.content);
                }
              },
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: const Column(
          children: [
            CodeToolbar(),
            Expanded(
              child: CodeEditor(),
            ),
          ],
        ),
      ),
      bottomSheet: const OutputSheet(),
    );
  }
}
