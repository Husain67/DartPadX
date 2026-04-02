import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
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
                  'Output',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (state.executionTime.isNotEmpty || state.memory.isNotEmpty)
                      Text(
                        '${state.executionTime} ${state.memory}'.trim(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 20),
                      onPressed: () {
                        ref.read(compilerProvider.notifier).clearOutput();
                      },
                      tooltip: 'Clear Output',
                    )
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: state.isExecuting
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.stdout.isNotEmpty)
                          Text(
                            state.stdout,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.success,
                            ),
                          ),
                        if (state.stderr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              state.stderr,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        if (state.stdout.isEmpty && state.stderr.isEmpty && !state.isExecuting)
                          const Text(
                            'No output.',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
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
