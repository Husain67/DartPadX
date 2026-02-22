import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../core/theme.dart';

class OutputSheet extends ConsumerWidget {
  final ScrollController? scrollController;

  const OutputSheet({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);
    final result = executionState.result;
    final error = executionState.error;
    final isLoading = executionState.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Output Console',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (result != null || error != null)
                  TextButton(
                    onPressed: () {
                      ref.read(executionProvider.notifier).clearOutput();
                    },
                    child: const Text('Clear', style: TextStyle(color: AppTheme.accentYellow)),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow))
                : SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (error != null)
                          Text(
                            error,
                            style: const TextStyle(color: AppTheme.errorRed, fontFamily: 'monospace'),
                          ),
                        if (result != null) ...[
                          if (result.stdout.isNotEmpty)
                            Text(
                              result.stdout,
                              style: const TextStyle(color: AppTheme.successGreen, fontFamily: 'monospace'),
                            ),
                          if (result.stderr.isNotEmpty)
                             Text(
                              result.stderr,
                              style: const TextStyle(color: AppTheme.errorRed, fontFamily: 'monospace'),
                            ),
                           if (result.stdout.isEmpty && result.stderr.isEmpty && result.error == null)
                            const Text(
                              "Execution completed (no output)",
                               style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                            ),
                           const SizedBox(height: 16),
                           if (result.executionTime != null || result.memory != null)
                             Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: Colors.black,
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.white12),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   if (result.executionTime != null)
                                     Text(
                                       'Time: ${result.executionTime}ms',
                                       style: const TextStyle(color: Colors.grey, fontSize: 12),
                                     ),
                                   if (result.executionTime != null && result.memory != null)
                                     const SizedBox(width: 16),
                                   if (result.memory != null)
                                     Text(
                                       'Memory: ${result.memory}KB',
                                       style: const TextStyle(color: Colors.grey, fontSize: 12),
                                     ),
                                 ],
                               ),
                             ),
                        ],
                        if (result == null && error == null && !isLoading)
                           const Text(
                             "Ready to run code.",
                             style: TextStyle(color: Colors.grey),
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
