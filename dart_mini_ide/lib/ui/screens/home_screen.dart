import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../widgets/code_editor.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';
import '../widgets/file_tabs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFile = ref.watch(currentFileProvider);
    final isRunning = ref.watch(executionLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              width: 80,
              height: 36,
              child: ElevatedButton(
                onPressed: isRunning
                    ? null
                    : () {
                        if (currentFile != null) {
                          ref.read(executionControllerProvider).runCode(currentFile.content);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isRunning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.black, size: 18),
                          SizedBox(width: 4),
                          Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      body: const Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 48, child: FileTabs()),
              Toolbar(),
              Expanded(child: CodeEditor()),
            ],
          ),
          OutputSheet(),
        ],
      ),
    );
  }
}
