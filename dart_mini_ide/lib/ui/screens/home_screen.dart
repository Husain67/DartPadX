import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/code_editor.dart';
import '../widgets/output_sheet.dart';
import '../widgets/toolbar.dart';
import '../../providers/execution_provider.dart';
import '../../providers/file_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final currentFile = ref.watch(fileProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false, // Let keyboard overlay editor
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
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
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: executionState.isRunning
                  ? null
                  : () {
                      if (currentFile != null) {
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                        ref.read(executionProvider.notifier).runCode(
                          currentFile.content,
                          stdin: '', // Prompt for stdin if needed? For now empty.
                        );
                        // Open output sheet? It's always visible as a handle.
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: executionState.isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Row(
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 4),
                        Text('Run'),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const Toolbar(),
              Expanded(
                child: const CodeEditorWidget(),
              ),
              // Space for output sheet handle when collapsed
              const SizedBox(height: 60),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
