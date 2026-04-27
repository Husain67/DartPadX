import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

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
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF333333), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Console Output',
                  style: TextStyle(
                      color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(color: Color(0xFF333333)),
              // Output Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Text('Running...', style: TextStyle(color: Colors.grey)),
                    if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                    if (execState.stderr.isNotEmpty)
                      Text(execState.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                    if (execState.time.isNotEmpty || execState.memory.isNotEmpty)
                       Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Row(
                           children: [
                             if (execState.time.isNotEmpty)
                               Text('⏱ ${execState.time}ms  ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                             if (execState.memory.isNotEmpty)
                               Text('💾 ${execState.memory}MB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                           ],
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
