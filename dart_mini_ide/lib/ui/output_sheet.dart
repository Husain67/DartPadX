import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a1a),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(),
              _buildHeader(context, ref, state),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  child: _buildOutputContent(state),
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, ExecutionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Output Console',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          ),
          Row(
            children: [
              if (state.executionTime.isNotEmpty) ...[
                Text(
                  'Time: \${state.executionTime}ms',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
                onPressed: () {
                  ref.read(executionProvider.notifier).clearOutput();
                },
                tooltip: 'Clear Output',
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputContent(ExecutionState state) {
    if (state.isExecuting) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
            child: CircularProgressIndicator(
          color: Color(0xFFFACC15),
        )),
      );
    }

    if (state.stdout.isEmpty && state.stderr.isEmpty && state.error.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No output.', style: TextStyle(color: Colors.white38)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.stdout.isNotEmpty) ...[
          Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
          const SizedBox(height: 8),
        ],
        if (state.stderr.isNotEmpty) ...[
          const Text('STDERR:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
          const SizedBox(height: 8),
        ],
        if (state.error.isNotEmpty) ...[
          const Text('ERROR:', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(state.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
        ],
      ],
    );
  }
}
