import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/providers/execution_provider.dart';

class OutputSheetWidget extends ConsumerWidget {
  const OutputSheetWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        if (executionState.executionTime != null)
                          Text(
                            '\${executionState.executionTime} • ',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        if (executionState.memoryUsage != null)
                          Text(
                            '\${executionState.memoryUsage} • ',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Clear Output',
                          onPressed: () {
                            ref.read(executionProvider.notifier).clearOutput();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Content
              Expanded(
                child: executionState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: SelectableText.rich(
                            TextSpan(
                              children: [
                                if (executionState.stdout.isNotEmpty)
                                  TextSpan(
                                    text: executionState.stdout,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                if (executionState.stdout.isNotEmpty &&
                                    (executionState.stderr.isNotEmpty || executionState.error != null))
                                  const TextSpan(text: '\n'),
                                if (executionState.stderr.isNotEmpty)
                                  TextSpan(
                                    text: executionState.stderr,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                if (executionState.error != null)
                                  TextSpan(
                                    text: '\n\${executionState.error}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (executionState.stdout.isEmpty &&
                                    executionState.stderr.isEmpty &&
                                    executionState.error == null)
                                  const TextSpan(
                                    text: 'No output yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
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
