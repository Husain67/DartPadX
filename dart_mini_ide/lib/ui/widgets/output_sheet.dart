import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Console Output',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: state.isRunning
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFACC15)),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (state.stdout.isNotEmpty)
                            Text(
                              state.stdout,
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 14),
                            ),
                          if (state.stderr.isNotEmpty)
                            Text(
                              state.stderr,
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 14),
                            ),
                          if (state.stdout.isEmpty && state.stderr.isEmpty)
                            const Text(
                              'No output.',
                              style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                            ),
                          const SizedBox(height: 16),
                          if (state.time.isNotEmpty || state.memory.isNotEmpty)
                            Text(
                              'Execution Time: \${state.time} | Memory: \${state.memory}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
