import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.05,
      minChildSize: 0.05,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ),
              const Divider(color: Color(0xFF333333)),
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

  Widget _buildContent(ExecutionState state) {
    if (state.isExecuting) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)));
    }

    if (state.result == null) {
      return const Center(child: Text('Run code to see output', style: TextStyle(color: Colors.grey)));
    }

    final result = state.result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.stdout.isNotEmpty)
          Text(result.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
        if (result.stderr.isNotEmpty)
          Text(result.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
        if (result.error.isNotEmpty)
          Text(result.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Time: ${result.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(width: 8),
            Text('Mem: ${result.memory} limit rem.', style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        )
      ],
    );
  }
}
