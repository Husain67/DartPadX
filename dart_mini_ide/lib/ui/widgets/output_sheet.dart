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
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Console Output", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clear();
                          },
                        )
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    if (execState.isExecuting)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (execState.stdout.isNotEmpty) ...[
                      const Text('STDOUT', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(execState.stdout, style: const TextStyle(color: AppTheme.successColor, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                    ],
                    if (execState.stderr.isNotEmpty) ...[
                      const Text('STDERR', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(execState.stderr, style: const TextStyle(color: AppTheme.errorColor, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                    ],
                    if (execState.error.isNotEmpty) ...[
                      const Text('ERROR', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(execState.error, style: const TextStyle(color: AppTheme.errorColor, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                    ],
                    if (execState.time.isNotEmpty || execState.memory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            if (execState.time.isNotEmpty)
                              Text('Time: ${execState.time} ms', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            if (execState.time.isNotEmpty && execState.memory.isNotEmpty)
                              const SizedBox(width: 16),
                            if (execState.memory.isNotEmpty)
                              Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      )
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
