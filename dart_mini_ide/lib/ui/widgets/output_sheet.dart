import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Console Output', style: TextStyle(color: AppTheme.whiteCream, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                  onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: execState.isRunning
                ? const Center(child: CircularProgressIndicator(color: AppTheme.yellowAccent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (execState.stdout.isNotEmpty)
                          Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                        if (execState.stderr.isNotEmpty)
                          Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                        if (execState.error.isNotEmpty)
                          Text(execState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                        if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'Time: ${execState.executionTime} | Memory: ${execState.memory}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        if (execState.stdout.isEmpty && execState.stderr.isEmpty && execState.error.isEmpty && !execState.isRunning)
                          const Text('No output yet. Run your code!', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
