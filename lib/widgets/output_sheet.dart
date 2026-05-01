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
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Time: ${execState.executionTime} | Mem: ${execState.memory}',
                          style: const TextStyle(color: Color(0xFFFACC15), fontSize: 12),
                        ),
                      ),
                    if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                    if (execState.stderr.isNotEmpty)
                      Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    if (execState.error.isNotEmpty)
                      Text(execState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty && execState.error.isEmpty && !execState.isExecuting)
                      const Text('No output', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        labelText: 'Standard Input (stdin)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
                      ),
                      maxLines: 3,
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
