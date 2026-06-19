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
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        if (state.time.isNotEmpty) ...[
                          Text(
                            'Time: \${state.time}s',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (state.memory.isNotEmpty) ...[
                          Text(
                            'Mem: \${state.memory}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clear();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // Content
              Expanded(
                child: state.isExecuting
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (state.output.isNotEmpty)
                            Text(
                              state.output,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (state.error.isNotEmpty)
                            Text(
                              state.error,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (state.output.isEmpty && state.error.isEmpty && !state.isExecuting)
                            const Text(
                              'No output.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
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
