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
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Output Console',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: executionState.isExecuting
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (executionState.stdout.isNotEmpty) ...[
                            const Text('STDOUT:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(executionState.stdout, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                            const SizedBox(height: 16),
                          ],
                          if (executionState.stderr.isNotEmpty) ...[
                            const Text('STDERR:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(executionState.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                            const SizedBox(height: 16),
                          ],
                          if (executionState.error.isNotEmpty) ...[
                            const Text('ERROR:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(executionState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                            const SizedBox(height: 16),
                          ],
                          if (executionState.executionTime.isNotEmpty || executionState.memory.isNotEmpty) ...[
                            const Divider(color: Colors.white24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (executionState.executionTime.isNotEmpty)
                                  Text('Time: ${executionState.executionTime}', style: const TextStyle(color: Colors.grey)),
                                if (executionState.memory.isNotEmpty)
                                  Text('Memory: ${executionState.memory}', style: const TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                          if (executionState.stdout.isEmpty && executionState.stderr.isEmpty && executionState.error.isEmpty && !executionState.isExecuting)
                            const Center(
                              child: Text('No output', style: TextStyle(color: Colors.grey)),
                            ),
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
