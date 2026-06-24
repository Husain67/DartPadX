// ignore_for_file: prefer_const_constructors, unnecessary_const
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor ?? const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(context, execState, ref),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(execState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ExecutionState state, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Console Output',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            children: [
              if (state.executionTime.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${state.executionTime}ms',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20, color: Colors.white54),
                onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                tooltip: 'Clear Output',
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
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFFACC15)),
        ),
      );
    }

    if (state.stdout.isEmpty && state.stderr.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Ready to run code.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.stdout.isNotEmpty)
          Text(
            state.stdout,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.greenAccent,
            ),
          ),
        if (state.stderr.isNotEmpty) ...[
          if (state.stdout.isNotEmpty) const SizedBox(height: 16),
          Text(
            state.stderr,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }
}
