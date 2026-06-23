import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A0A), // Deep black background for iOS style
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Console Output',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (executionState.isExecuting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFACC15),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white54, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: executionState.result == null
                      ? const Text(
                          'No output. Run your code to see results here.',
                          style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (executionState.result!.stdout.isNotEmpty)
                              Text(
                                executionState.result!.stdout,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            if (executionState.result!.stderr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  executionState.result!.stderr,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              'Time: ${executionState.result!.executionTime}  Memory: ${executionState.result!.memory}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
