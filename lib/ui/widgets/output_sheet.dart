import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_notifier.dart';
import '../../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
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
                  color: AppTheme.textLightColor.withValues(alpha: 0.5),
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
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text(
                            '⏱ ${execState.executionTime}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                          ),
                        const SizedBox(width: 8),
                        if (execState.memory.isNotEmpty && execState.memory != 'N/A')
                          Text(
                            '💾 ${execState.memory}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textLightColor),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear_all, size: 20),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clearOutput();
                          },
                          tooltip: 'Clear Output',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Colors.greenAccent,
                          fontSize: 14,
                        ),
                      ),
                    if (execState.stderr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          execState.stderr,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty && !execState.isRunning)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32.0),
                          child: Text(
                            'No output yet. Run your code!',
                            style: TextStyle(color: AppTheme.textLightColor),
                          ),
                        ),
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
