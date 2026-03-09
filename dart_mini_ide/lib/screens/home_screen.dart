import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/file_tabs_widget.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExecuting = ref.watch(executionProvider.select((s) => s.isExecuting));

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by gradient container
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: AppTheme.pureBlack,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Material(
              color: AppTheme.primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: isExecuting
                    ? null
                    : () {
                        final activeFile = ref.read(fileProvider.notifier).activeFile;
                        if (activeFile != null) {
                          ref.read(executionProvider.notifier).executeCode(activeFile.content);
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      if (isExecuting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppTheme.pureBlack,
                            strokeWidth: 2,
                          ),
                        )
                      else ...[
                        const Icon(Icons.play_arrow_rounded, color: AppTheme.pureBlack),
                        const SizedBox(width: 4),
                        const Text(
                          'Run',
                          style: TextStyle(
                            color: AppTheme.pureBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const Stack(
          children: [
            Column(
              children: [
                ToolbarWidget(),
                FileTabsWidget(),
                Expanded(
                  child: CodeEditorWidget(),
                ),
                SizedBox(height: 60), // Space for output sheet handle
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: OutputSheet(),
            ),
          ],
        ),
      ),
    );
  }
}
