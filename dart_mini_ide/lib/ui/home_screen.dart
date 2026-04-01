import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/execution_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'editor_area.dart';
import 'file_tabs.dart';
import 'output_sheet.dart';
import 'toolbar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(AppConstants.appName),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                AppConstants.version,
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
          IconButton(
            icon: const Icon(Icons.input, color: AppColors.accentYellow),
            tooltip: 'Provide Stdin',
            onPressed: () {
              _showStdinDialog(context, ref);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: executionState.isExecuting
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).executeCode();
                    },
              icon: executionState.isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Toolbar(),
                const FileTabs(),
                const Expanded(
                  child: EditorArea(),
                ),
                // Padding for OutputSheet when closed
                const SizedBox(height: 56),
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }

  void _showStdinDialog(BuildContext context, WidgetRef ref) {
    final stdinCtrl = TextEditingController(text: ref.read(executionProvider).stdinInput);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Standard Input (stdin)'),
        content: TextField(
          controller: stdinCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter multi-line stdin here...',
            filled: true,
            fillColor: AppColors.editorBackground,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(executionProvider.notifier).setStdin(stdinCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}