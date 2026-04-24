import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: Colors.white10),
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
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Console Output',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty) ...[
                          Text(
                            '${execState.executionTime}ms',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clearOutput();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Output Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    if (execState.stderr.isNotEmpty) ...[
                      if (execState.stdout.isNotEmpty) const SizedBox(height: 16),
                      Text(
                        execState.stderr,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text(
                        'No output yet. Press Run.',
                        style: TextStyle(
                          color: Colors.grey,
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
