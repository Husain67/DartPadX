import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../utils/theme.dart';
import 'toolbar_widget.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider).activeFile;
    final isRunning = ref.watch(executionProvider).isRunning;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 10,
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
              onPressed: isRunning || activeFile == null
                  ? null
                  : () {
                      ref
                          .read(executionProvider.notifier)
                          .executeCode(activeFile.content);
                    },
              icon: isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.textDark,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainBackgroundDecoration,
        child: Column(
          children: [
            const ToolbarWidget(),
            const Expanded(
              child: EditorWidget(),
            ),
          ],
        ),
      ),
      bottomSheet: const OutputSheet(),
    );
  }
}
