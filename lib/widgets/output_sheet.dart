import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(compilerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        if (executionState.isRunning)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFACC15)),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(compilerProvider.notifier).clearOutput(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),

              // Output Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (executionState.stdout.isNotEmpty)
                      Text(
                        executionState.stdout,
                        style: const TextStyle(color: Colors.green, fontFamily: 'monospace'),
                      ),
                    if (executionState.stderr.isNotEmpty)
                      Text(
                        executionState.stderr,
                        style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                      ),
                    if (executionState.executionTime.isNotEmpty || executionState.memory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          '[Finished in ${executionState.executionTime}]',
                          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    if (executionState.stdout.isEmpty && executionState.stderr.isEmpty && !executionState.isRunning)
                      const Center(
                        child: Text(
                          'No output yet. Run your code!',
                          style: TextStyle(color: Colors.grey),
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
