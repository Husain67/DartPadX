import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    isDense: true,
                  ),
                  onChanged: (val) => ref.read(executionProvider.notifier).setStdin(val),
                  maxLines: null,
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (executionState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (executionState.stdout.isNotEmpty)
                        Text(
                          executionState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                        ),
                      if (executionState.stderr.isNotEmpty)
                        Text(
                          executionState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                        ),
                      if (executionState.executionTime.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Time: \${executionState.executionTime}ms',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
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
