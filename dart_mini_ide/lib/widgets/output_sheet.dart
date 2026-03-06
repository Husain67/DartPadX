import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1, // Initial minimized height
      minChildSize: 0.1,
      maxChildSize: 0.8, // Max expanded height
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF151515), // Deep dark gray
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Draggable Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                      tooltip: 'Clear Output',
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),

              // Content Area
              Expanded(
                child: _buildContent(execState, scrollController),
              ),

              // Status Bar
              if (execState.hasRun && !execState.isExecuting)
                Container(
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time: ${execState.time} s',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        'Mem: ${execState.memory}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildContent(ExecutionState state, ScrollController controller) {
    if (state.isExecuting) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentYellow),
      );
    }

    if (!state.hasRun) {
      return const Center(
        child: Text(
          'Run your code to see output here.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        if (state.stdout.isNotEmpty)
          Text(
            state.stdout,
            style: const TextStyle(
              color: AppTheme.successGreen,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        if (state.stderr.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: state.stdout.isNotEmpty ? 16.0 : 0),
            child: Text(
              state.stderr,
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        if (state.stdout.isEmpty && state.stderr.isEmpty)
          const Text(
            'Program exited with no output.',
            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }
}
