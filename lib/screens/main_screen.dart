import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/editor_area.dart';
import '../widgets/output_sheet.dart';
import '../providers/execution_provider.dart';
import '../widgets/examples_gallery.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      drawer: const ExamplesGallery(),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: execState.isRunning
                  ? null
                  : () => ref.read(executionProvider.notifier).executeCode(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: execState.isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: const Stack(
        children: [
          Column(
            children: [
              Toolbar(),
              Expanded(child: EditorArea()),
            ],
          ),
          OutputSheet(),
        ],
      ),
    );
  }
}
