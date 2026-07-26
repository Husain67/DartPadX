import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    if (!execState.showSheet) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgLightDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(128),
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref
                              .read(executionProvider.notifier)
                              .clearOutput(),
                          tooltip: 'Clear Output',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () =>
                              ref.read(executionProvider.notifier).closeSheet(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryAccent))
                    else ...[
                      if (execState.time.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                              'Time: \${execState.time} | Memory: \${execState.memory}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ),
                      if (execState.stdout.isNotEmpty)
                        Text(execState.stdout,
                            style: const TextStyle(
                                color: Colors.green, fontFamily: 'monospace')),
                      if (execState.stderr.isNotEmpty)
                        Text(execState.stderr,
                            style: const TextStyle(
                                color: Colors.red, fontFamily: 'monospace')),
                      if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                        const Text('No output',
                            style: TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic)),
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
