import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/output_provider.dart';
import '../theme.dart';

class OutputSheetWidget extends ConsumerWidget {
  const OutputSheetWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputState = ref.watch(outputProvider);

    if (!outputState.showSheet) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundEnd,
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
              _buildHandle(ref),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (outputState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    else ...[
                      if (outputState.executionTime.isNotEmpty || outputState.memory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Time: ${outputState.executionTime} | Mem: ${outputState.memory}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      if (outputState.stdout.isNotEmpty)
                        Text(
                          outputState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                        ),
                      if (outputState.stderr.isNotEmpty)
                        Text(
                          outputState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                        ),
                      if (outputState.stdout.isEmpty && outputState.stderr.isEmpty)
                        const Text(
                          'No output',
                          style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
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

  Widget _buildHandle(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(outputProvider.notifier).toggleSheet(false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
