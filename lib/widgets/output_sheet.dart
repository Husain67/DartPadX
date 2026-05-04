import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                    const Text(
                      'Console Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (executionState.executionTime.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '\${executionState.executionTime}ms',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ),
                        if (executionState.memory.isNotEmpty)
                          Text(
                            '\${executionState.memory}B',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                          tooltip: 'Clear Output',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: executionState.isExecuting
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (executionState.stdout.isNotEmpty)
                            Text(
                              executionState.stdout,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (executionState.stderr.isNotEmpty)
                            Text(
                              executionState.stderr,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (executionState.error.isNotEmpty)
                            Text(
                              executionState.error,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (executionState.stdout.isEmpty &&
                              executionState.stderr.isEmpty &&
                              executionState.error.isEmpty)
                            Text(
                              'Ready. Run your code.',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
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
