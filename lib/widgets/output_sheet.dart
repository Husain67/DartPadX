import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../core/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
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
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (state.executionTime.isNotEmpty) ...[
                          Text('⏱️ ${state.executionTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (state.memory.isNotEmpty) ...[
                          Text('💾 ${state.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.isExecuting)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    else if (state.stdout.isEmpty && state.stderr.isEmpty && state.error.isEmpty)
                      const Text('Run code to see output here...', style: TextStyle(color: Colors.grey))
                    else ...[
                      if (state.stdout.isNotEmpty)
                        Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (state.stderr.isNotEmpty)
                        Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                      if (state.error.isNotEmpty)
                        Text(state.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
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
