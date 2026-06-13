import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                height: 4,
                width: 40,
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
                    const Text(
                      'Output Console',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                    )
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderColor),
              Expanded(
                child: execState.isExecuting
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.result == null)
                            const Text(
                              'No output yet. Run your code!',
                              style: TextStyle(color: AppTheme.textSecondary),
                            )
                          else ...[
                            if (execState.result!.stdout.isNotEmpty) ...[
                              const Text('STDOUT', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(execState.result!.stdout, style: const TextStyle(fontFamily: 'monospace')),
                              const SizedBox(height: 16),
                            ],
                            if (execState.result!.stderr.isNotEmpty) ...[
                              const Text('STDERR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(execState.result!.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                              const SizedBox(height: 16),
                            ],
                            if (execState.result!.error.isNotEmpty) ...[
                              const Text('ERROR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(execState.result!.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                              const SizedBox(height: 16),
                            ],
                            const Divider(color: AppTheme.borderColor),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Time: \\${execState.result!.executionTime.isEmpty ? "N/A" : execState.result!.executionTime}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text('Memory: \\${execState.result!.memory.isEmpty ? "N/A" : execState.result!.memory}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
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
