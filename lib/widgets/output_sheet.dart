import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../core/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: Colors.white24, width: 1)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.pureWhite)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty) ...[
                          Icon(Icons.timer, size: 14, color: AppTheme.primaryAccent),
                          const SizedBox(width: 4),
                          Text(execState.executionTime, style: const TextStyle(fontSize: 12, color: AppTheme.pureWhite)),
                          const SizedBox(width: 12),
                        ],
                        if (execState.memory.isNotEmpty) ...[
                          Icon(Icons.memory, size: 14, color: AppTheme.primaryAccent),
                          const SizedBox(width: 4),
                          Text(execState.memory, style: const TextStyle(fontSize: 12, color: AppTheme.pureWhite)),
                          const SizedBox(width: 12),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: AppTheme.pureWhite),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clear();
                          },
                          tooltip: 'Clear Output',
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    else if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text('No output yet. Run your code.', style: TextStyle(color: Colors.white54))
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(execState.stdout, style: const TextStyle(color: AppTheme.successGreen, fontFamily: 'monospace')),
                      if (execState.stderr.isNotEmpty)
                        Text(execState.stderr, style: const TextStyle(color: AppTheme.errorRed, fontFamily: 'monospace')),
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
