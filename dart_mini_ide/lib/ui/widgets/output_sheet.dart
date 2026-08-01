import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/output_provider.dart';
import '../../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputState = ref.watch(outputProvider);

    if (!outputState.isVisible) {
      return const SizedBox.shrink();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.pureBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            children: [
              // Handle
              GestureDetector(
                onTap: () {
                  ref.read(outputProvider.notifier).toggleVisibility();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
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
                      'Console Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        if (outputState.executionTime.isNotEmpty)
                          Text(
                            '${outputState.executionTime}ms',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: () {
                            ref.read(outputProvider.notifier).toggleVisibility();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Content
              Expanded(
                child: outputState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryAccent,
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (outputState.stdout.isNotEmpty)
                            Text(
                              outputState.stdout,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (outputState.stderr.isNotEmpty)
                            Text(
                              outputState.stderr,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (outputState.error.isNotEmpty)
                            Text(
                              outputState.error,
                              style: const TextStyle(
                                color: Colors.red,
                                fontFamily: 'monospace',
                              ),
                            ),
                          if (outputState.stdout.isEmpty &&
                              outputState.stderr.isEmpty &&
                              outputState.error.isEmpty)
                            const Text(
                              'No output.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
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
