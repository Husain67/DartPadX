import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1, // Start small
      minChildSize: 0.08,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 16,
                spreadRadius: 2,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output Console',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (execState.result != null)
                      Row(
                        children: [
                          Text(
                            execState.result!.executionTime,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          if (execState.result!.memory.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              execState.result!.memory,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => ref.read(executionProvider.notifier).clear(),
                            child: const Icon(Icons.block, color: Colors.white54, size: 18),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.white10),
              // Content
              Expanded(
                child: execState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFACC15),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.result != null) ...[
                            if (execState.result!.error.isNotEmpty) ...[
                              const Text('EXCEPTION:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              SelectableText(
                                execState.result!.error,
                                style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (execState.result!.stderr.isNotEmpty) ...[
                              const Text('STDERR:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              SelectableText(
                                execState.result!.stderr,
                                style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (execState.result!.stdout.isNotEmpty) ...[
                              const Text('STDOUT:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              SelectableText(
                                execState.result!.stdout,
                                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                              ),
                            ] else if (execState.result!.error.isEmpty && execState.result!.stderr.isEmpty) ...[
                               const Text('Process finished with no output.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            ]
                          ] else
                             const Center(
                               child: Text(
                                 'Ready to execute code.',
                                 style: TextStyle(color: Colors.white24),
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
