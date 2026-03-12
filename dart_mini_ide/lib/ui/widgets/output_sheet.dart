import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHandle(),
          _buildHeader(ref),
          Expanded(
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: _buildContent(state),
            ),
          ),
          if (state.executionTime.isNotEmpty || state.memory.isNotEmpty)
            _buildMetrics(state),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Output Console',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
                onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                tooltip: 'Clear Output',
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                onPressed: () => ref.read(executionProvider.notifier).hideOutput(),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ExecutionState state) {
    if (state.isRunning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentYellow),
            SizedBox(height: 16),
            Text('Executing code...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (state.stdout.isEmpty && state.stderr.isEmpty) {
      return const Center(
        child: Text(
          'Run code to see output here',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.stdout.isNotEmpty)
            Text(
              state.stdout,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
          if (state.stderr.isNotEmpty) ...[
            if (state.stdout.isNotEmpty) const SizedBox(height: 8),
            Text(
              state.stderr,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMetrics(ExecutionState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Row(
        children: [
          if (state.executionTime.isNotEmpty) ...[
            const Icon(Icons.timer, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              state.executionTime,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(width: 16),
          ],
          if (state.memory.isNotEmpty) ...[
            const Icon(Icons.memory, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              state.memory,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
