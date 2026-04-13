import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
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
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.white54, size: 18),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              if (execState.rawResponse.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Raw Response:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          execState.rawResponse,
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // Execution Metrics
              if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.black26,
                  child: Row(
                    children: [
                      if (execState.executionTime.isNotEmpty)
                        Text('Time: ${execState.executionTime}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(width: 16),
                      if (execState.memory.isNotEmpty)
                        Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              // Console
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(
                          color: Color(0xFF4ADE80), // Green for stdout
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    if (execState.stderr.isNotEmpty) ...[
                      if (execState.stdout.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        execState.stderr,
                        style: const TextStyle(
                          color: Color(0xFFEF4444), // Red for stderr
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text(
                        'No output.',
                        style: TextStyle(
                          color: Colors.white38,
                          fontFamily: 'monospace',
                          fontSize: 13,
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
