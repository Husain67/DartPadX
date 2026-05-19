import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundGradientEnd,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
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
                        color: AppTheme.primaryYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // Content
              Expanded(
                child: executionState.isExecuting
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (executionState.executionTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'Time: ${executionState.executionTime} | Mem: ${executionState.memory.isEmpty ? "N/A" : executionState.memory}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          if (executionState.error.isNotEmpty)
                            Text(
                              'Exception:\n${executionState.error}',
                              style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                            ),
                          if (executionState.stderr.isNotEmpty)
                            Text(
                              'Standard Error:\n${executionState.stderr}',
                              style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                            ),
                          if (executionState.stdout.isNotEmpty)
                            Text(
                              executionState.stdout,
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                            ),
                          if (executionState.stdout.isEmpty &&
                              executionState.stderr.isEmpty &&
                              executionState.error.isEmpty &&
                              executionState.executionTime.isEmpty)
                            const Text(
                              'Run code to see output here.',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
