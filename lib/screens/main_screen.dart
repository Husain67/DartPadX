import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_console.dart';
import '../providers/execution_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryAccent),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: AppTheme.primaryAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : () => ref.read(executionProvider.notifier).runCode(),
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const Stack(
          children: [
            Column(
              children: [
                ToolbarWidget(),
                Expanded(child: EditorWidget()),
              ],
            ),
            OutputConsole(),
          ],
        ),
      ),
    );
  }
}
