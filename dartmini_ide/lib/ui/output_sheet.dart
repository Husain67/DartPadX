import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        if (execState.metrics.isNotEmpty)
                          Text(execState.metrics, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => ref.read(executionProvider.notifier).clearOutput(),
                          child: const Icon(Icons.clear_all, color: Colors.white54, size: 20),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Input (stdin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Console output
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                       const Text('Executing...', style: TextStyle(color: Color(0xFFFACC15), fontFamily: 'monospace', fontSize: 13)),
                    if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13)),
                    if (execState.stderr.isNotEmpty)
                      Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 13)),
                    if (!execState.isRunning && execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text('Ready.', style: TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 13)),
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
