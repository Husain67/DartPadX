import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const OutputSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Output Console',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                  onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: executionState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                : ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (executionState.executionTime.isNotEmpty || executionState.memory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Time: \${executionState.executionTime} • Memory: \${executionState.memory}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                      if (executionState.stdout.isNotEmpty)
                        Text(
                          executionState.stdout,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      if (executionState.stderr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            executionState.stderr,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (executionState.error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            executionState.error,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (executionState.stdout.isEmpty &&
                          executionState.stderr.isEmpty &&
                          executionState.error.isEmpty)
                        const Text(
                          'No output. Run some code!',
                          style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
