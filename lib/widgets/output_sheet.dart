import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execResult = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDragHandle(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: execResult.isRunning
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (execResult.time.isNotEmpty || execResult.memory.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                [
                                  if (execResult.time.isNotEmpty) 'Time: ${execResult.time}',
                                  if (execResult.memory.isNotEmpty) 'Memory: ${execResult.memory}',
                                ].join(' | '),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          if (execResult.stdout.isNotEmpty)
                            Text(
                              execResult.stdout,
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                            ),
                          if (execResult.stderr.isNotEmpty)
                            Text(
                              execResult.stderr,
                              style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 14),
                            ),
                          if (execResult.stdout.isEmpty && execResult.stderr.isEmpty && !execResult.isError)
                            const Text("No output", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
