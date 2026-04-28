import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';

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
            color: AppTheme.backgroundLight,
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.white54),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      if (execState.executionTime.isNotEmpty)
                        Text('Time: ${execState.executionTime}s  ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (execState.memory.isNotEmpty)
                        Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    else if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text('Ready...', style: TextStyle(color: Colors.white30, fontFamily: 'monospace'))
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        SelectableText(
                          execState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                        ),
                      if (execState.stderr.isNotEmpty)
                        SelectableText(
                          execState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 14),
                        ),
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
