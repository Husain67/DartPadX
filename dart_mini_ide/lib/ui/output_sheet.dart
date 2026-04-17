import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a1a),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              )
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                      tooltip: 'Clear Output',
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: execState.isRunning
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.result == null)
                            const Text('No output yet. Run your code!', style: TextStyle(color: Colors.grey))
                          else ...[
                            if (execState.result!.stdout.isNotEmpty)
                              Text(
                                execState.result!.stdout,
                                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                              ),
                            if (execState.result!.stderr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  execState.result!.stderr,
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                ),
                              ),
                            if (execState.result!.error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  execState.result!.error,
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                ),
                              ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white24),
                            Text(
                              "Execution Time: ${execState.result!.executionTime.isEmpty ? 'N/A' : execState.result!.executionTime}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            if (execState.result!.memory.isNotEmpty)
                              Text(
                                "Memory: ${execState.result!.memory}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
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
