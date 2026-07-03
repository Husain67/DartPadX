import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';
import 'package:dart_mini_ide/widgets/toolbar.dart';
import 'package:dart_mini_ide/widgets/file_tabs.dart';
import 'package:dart_mini_ide/widgets/code_editor_widget.dart';
import 'package:dart_mini_ide/widgets/output_sheet.dart';
import 'package:dart_mini_ide/providers/execution_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
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
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: execState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: execState.isRunning ? null : () => ref.read(executionProvider.notifier).runCode(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Stack(
          children: [
            Column(
              children: [
                ToolbarWidget(),
                FileTabsWidget(),
                Expanded(child: CodeEditorWidget()),
                SizedBox(height: 60), // Space for bottom sheet handle
              ],
            ),
            OutputSheet(),
          ],
        ),
      ),
    );
  }
}
