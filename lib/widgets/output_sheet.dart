import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output Console',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white54),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clearOutput();
                          },
                          tooltip: 'Clear Output',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
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
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: Color(0xFFFACC15)),
                        ),
                      )
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(
                          execState.stdout,
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 14),
                        ),
                      if (execState.stderr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            execState.stderr,
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.redAccent, fontSize: 14),
                          ),
                        ),
                      if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                        const Text(
                          'No output.',
                          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ],
                ),
              ),

              // Footer Stats
              if (!execState.isRunning && (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty))
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0A0A0A),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (execState.executionTime.isNotEmpty)
                        Text('Time: \${execState.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      if (execState.memory.isNotEmpty)
                        Text('Memory: \${execState.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
