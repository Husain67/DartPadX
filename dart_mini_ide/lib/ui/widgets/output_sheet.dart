import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                         IconButton(
                          icon: const Icon(Icons.clear_all, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: AppTheme.backgroundDark),
              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    else if (execState.result != null)
                      ..._buildOutputContent(execState.result!)
                    else
                      const Text('Ready to run code...', style: TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOutputContent(ExecutionResult result) {
    return [
      if (result.stdout.isNotEmpty)
        Text(result.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
      if (result.stderr.isNotEmpty)
        Text(result.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
      if (result.error.isNotEmpty)
        Text(result.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
      if (result.executionTime.isNotEmpty || result.memory.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Divider(color: AppTheme.backgroundDark),
        Text(
          'Time: ${result.executionTime} | Memory: ${result.memory}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ]
    ];
  }
}
