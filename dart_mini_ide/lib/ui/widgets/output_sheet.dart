import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../utils/constants.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
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
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppColors.accentYellow))
                    else if (execState.result != null)
                      ...[
                        if (execState.result!.stdout.isNotEmpty)
                          Text(execState.result!.stdout, style: const TextStyle(color: AppColors.successGreen, fontFamily: 'monospace')),
                        if (execState.result!.stderr.isNotEmpty)
                          Text(execState.result!.stderr, style: const TextStyle(color: AppColors.errorRed, fontFamily: 'monospace')),
                        if (execState.result!.error.isNotEmpty)
                          Text(execState.result!.error, style: const TextStyle(color: AppColors.errorRed, fontFamily: 'monospace')),
                        if (execState.result!.executionTime.isNotEmpty || execState.result!.memory.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          Text(
                            'Metrics: Time \${execState.result!.executionTime} | Mem \${execState.result!.memory}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ]
                      ]
                    else
                      const Text('Ready...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
