// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_notifier.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a1a),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text('${execState.executionTime} ms', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 8),
                        if (execState.memory.isNotEmpty)
                          Text('${execState.memory} KB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 8),
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
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isExecuting)
                      const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                    else if (execState.stderr.isNotEmpty)
                      Text(
                        execState.stderr,
                        style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                      )
                    else if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                      )
                    else
                      const Text(
                        'No output',
                        style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                      ),

                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    const Text('Standard Input (stdin):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter input for your program...',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Color(0xFF050505),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                      maxLines: null,
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
