import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';
import '../core/theme.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(fileProvider).activeFile;
    final settings = ref.watch(settingsProvider);
    final isExecuting = ref.watch(executionProvider).isExecuting;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: isExecuting
                  ? null
                  : () {
                      if (activeFile != null) {
                        final stdin = ref.read(stdinProvider);
                        final preset = settings.activePreset;
                        if (preset != null) {
                          ref.read(executionProvider.notifier).executeCode(
                                activeFile.content,
                                stdin,
                                preset,
                              );
                        }
                      }
                    },
              icon: isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const ToolbarWidget(),
              const Expanded(child: EditorWidget()),
              // Input field for stdin
              Container(
                padding: const EdgeInsets.all(8),
                color: AppTheme.surfaceColor,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              const SizedBox(height: 100), // Space for bottom sheet
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
