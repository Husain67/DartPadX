import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import 'editor/code_editor_view.dart';
import 'widgets/main_toolbar.dart';
import 'widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  ref.read(executionProvider.notifier).executeCode(activeFile.content);
                }
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const SafeArea(
          child: Column(
            children: [
              MainToolbar(),
              Expanded(
                child: Stack(
                  children: [
                    CodeEditorView(),
                    OutputSheet(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
