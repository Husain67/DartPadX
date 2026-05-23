import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputConsole extends ConsumerWidget {
  const OutputConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.8,
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (executionState.executionTime.isNotEmpty) ...[
                          Text(
                            'Time: ${executionState.executionTime}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (executionState.memory.isNotEmpty) ...[
                          Text(
                            'Mem: ${executionState.memory}',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clear();
                          },
                          tooltip: 'Clear Output',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              // Content
              Expanded(
                child: executionState.isExecuting
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFACC15)),
                      )
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
                                fontSize: 14,
                              ),
                            ),
                          if (executionState.stderr.isNotEmpty)
                            Text(
                              executionState.stderr,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          if (executionState.error.isNotEmpty)
                            Text(
                              executionState.error,
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                            ),
                          if (executionState.stdout.isEmpty &&
                              executionState.stderr.isEmpty &&
                              executionState.error.isEmpty)
                            Text(
                              'Ready.',
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
