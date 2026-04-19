import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
            ]
          ),
          child: Column(
            children: [
              _buildHandle(ref),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow)),
                    if (!execState.isRunning && execState.executionTime != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("Time: ${execState.executionTime}ms | Mem: ${execState.memory ?? 'N/A'}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ),
                    if (execState.stdout != null && execState.stdout!.isNotEmpty)
                      _buildOutputBlock(execState.stdout!, AppTheme.successGreen),
                    if (execState.stderr != null && execState.stderr!.isNotEmpty)
                      _buildOutputBlock(execState.stderr!, AppTheme.errorRed),
                    if (execState.error != null && execState.error!.isNotEmpty)
                      _buildOutputBlock(execState.error!, AppTheme.errorRed),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // balance
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
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
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: SelectableText(
        text,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}
