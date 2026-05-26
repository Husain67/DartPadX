import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clear(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Output Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (executionState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow)),
                    if (!executionState.isRunning) ...[
                      if (executionState.stdout.isNotEmpty)
                        Text(executionState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (executionState.stderr.isNotEmpty)
                        Text(executionState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                      if (executionState.error.isNotEmpty)
                        Text(executionState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      if (executionState.executionTime.isNotEmpty || executionState.memory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Time: ${executionState.executionTime}ms | Memory: ${executionState.memory}MB',
                            style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
                          ),
                        ),
                    ]
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
