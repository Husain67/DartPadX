import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);
    final hasOutput = executionState.stdout.isNotEmpty ||
                      executionState.stderr.isNotEmpty ||
                      executionState.error.isNotEmpty;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -10 && !_isExpanded) {
          setState(() => _isExpanded = true);
        } else if (details.delta.dy > 10 && _isExpanded) {
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? MediaQuery.of(context).size.height * 0.5 : 100,
        decoration: const BoxDecoration(
          color: AppColors.backgroundEnd,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.buttonBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Output',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      if (executionState.executionTime.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${executionState.executionTime}ms',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      if (executionState.memory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${executionState.memory}B',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      if (hasOutput)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.buttonBorder, height: 1),
            Expanded(
              child: executionState.isExecuting
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!hasOutput && !executionState.isExecuting)
                            const Text(
                              'No output. Run your code.',
                              style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          if (executionState.stdout.isNotEmpty)
                            Text(
                              executionState.stdout,
                              style: const TextStyle(
                                color: AppColors.outputGreen,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (executionState.stderr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                executionState.stderr,
                                style: const TextStyle(
                                  color: AppColors.outputRed,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          if (executionState.error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                executionState.error,
                                style: const TextStyle(
                                  color: AppColors.outputRed,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
const bold = FontWeight.bold;
