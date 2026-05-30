import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/execution_provider.dart';
import '../../core/theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execution = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          Expanded(
            flex: 1,
            child: execution.isRunning
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (execution.stdout.isNotEmpty)
                          Text(execution.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                        if (execution.stderr.isNotEmpty)
                          Text(execution.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                        if (execution.error.isNotEmpty && execution.error != 'Executing...')
                          Text(execution.error, style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'monospace')),
                        if (execution.time.isNotEmpty || execution.memory.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 8),
                          Text('Time: ${execution.time} | Memory: ${execution.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ]
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
