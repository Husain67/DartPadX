import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundEnd,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Console Output',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (execState.executionTime.isNotEmpty) ...[
                    Text(
                      'Time: \${execState.executionTime}ms',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (execState.memory.isNotEmpty) ...[
                    Text(
                      'Mem: \${execState.memory}MB',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      ref.read(executionProvider.notifier).clearOutput();
                    },
                  ),
                ],
              )
            ],
          ),
          const Divider(color: AppTheme.dividerColor),
          Expanded(
            child: SingleChildScrollView(
              child: execState.isRunning
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (execState.stdout.isNotEmpty)
                          Text(
                            execState.stdout,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (execState.stderr.isNotEmpty)
                          Text(
                            execState.stderr,
                            style: const TextStyle(
                              color: Colors.red,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                          const Text(
                            'Output will appear here...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
