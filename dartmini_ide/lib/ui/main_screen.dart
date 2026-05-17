import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/execution_provider.dart';
import 'toolbar.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deep black background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : () => ref.read(executionProvider.notifier).executeCode(),
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              Expanded(child: EditorWidget()),
            ],
          ),
          OutputSheet(),
        ],
      ),
    );
  }
}
