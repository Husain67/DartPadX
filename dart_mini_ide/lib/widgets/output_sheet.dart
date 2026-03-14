import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../utils/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: 24,
                  ),
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                      tooltip: 'Clear Output',
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (executionState.isLoading)
                          const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                        else if (executionState.stdout.isNotEmpty || executionState.stderr.isNotEmpty) ...[
                          if (executionState.stdout.isNotEmpty)
                            Text(
                              executionState.stdout,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: AppTheme.successGreen,
                              ),
                            ),
                          if (executionState.stderr.isNotEmpty)
                            Text(
                              executionState.stderr,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: AppTheme.errorRed,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (executionState.time.isNotEmpty)
                                Text('Time: ${executionState.time}', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 16),
                              if (executionState.memory.isNotEmpty)
                                Text('Mem: ${executionState.memory}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ] else
                          const Text('No output', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
