import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.08,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              GestureDetector(
                onVerticalDragUpdate: (_) {}, // Let sheet handle drag
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Hit test area
                  ),
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
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Console Output',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    if (executionState.isRunning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAccent),
                      ),
                    if (!executionState.isRunning && (executionState.stdout.isNotEmpty || executionState.stderr.isNotEmpty))
                      IconButton(
                        icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
                        onPressed: () {
                          ref.read(executionProvider.notifier).clearOutput();
                        },
                        tooltip: 'Clear Output',
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (executionState.error != null)
                      _buildOutputBlock(context, 'System Error', executionState.error!, AppTheme.errorRed),
                    if (executionState.stderr.isNotEmpty)
                      _buildOutputBlock(context, 'stderr', executionState.stderr, AppTheme.errorRed),
                    if (executionState.stdout.isNotEmpty)
                      _buildOutputBlock(context, 'stdout', executionState.stdout, AppTheme.successGreen),

                    if (!executionState.isRunning && executionState.executionTime > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Execution: ${executionState.executionTime}ms • Memory: ${executionState.memory}KB',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),

                    if (!executionState.isRunning &&
                        executionState.stdout.isEmpty &&
                        executionState.stderr.isEmpty &&
                        executionState.error == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Text(
                            'Run code to see output here',
                            style: TextStyle(color: Colors.white24),
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

  Widget _buildOutputBlock(BuildContext context, String label, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, top: 8),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              color: color.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
