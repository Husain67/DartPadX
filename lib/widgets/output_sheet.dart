import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.2,
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
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(ref),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (executionState.isRunning)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                        ),
                      ),
                    if (executionState.stdout.isNotEmpty)
                      _buildOutputBlock(executionState.stdout, Colors.greenAccent),
                    if (executionState.stderr.isNotEmpty)
                      _buildOutputBlock(executionState.stderr, Colors.redAccent),
                    if (!executionState.isRunning && executionState.stdout.isEmpty && executionState.stderr.isEmpty)
                      const Text('Output will appear here...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade600,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final state = ref.watch(executionProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Row(
            children: [
              if (state.time.isNotEmpty)
                Text('Time: \${state.time}s', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 8),
              if (state.memory.isNotEmpty)
                Text('Mem: \${state.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.clear_all, size: 20),
                onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                tooltip: 'Clear Output',
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOutputBlock(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: TextStyle(fontFamily: 'monospace', color: color, fontSize: 14),
      ),
    );
  }
}
