import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(
                          execState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                        ),
                      if (execState.stderr.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          execState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                        ),
                      ],
                      if (execState.error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          execState.error,
                          style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                        ),
                      ],
                      if (!execState.isRunning && execState.stdout.isEmpty && execState.stderr.isEmpty && execState.error.isEmpty)
                         const Text('No output yet. Run your code!', style: TextStyle(color: Colors.grey)),
                      if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty) ...[
                         const SizedBox(height: 16),
                         const Divider(color: Colors.grey),
                         const Text(
                           'Time: \${execState.executionTime} | Memory: \${execState.memory}',
                           style: TextStyle(color: Colors.grey, fontSize: 12),
                         )
                      ]
                    ],
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
