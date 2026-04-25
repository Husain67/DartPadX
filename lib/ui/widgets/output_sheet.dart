import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

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
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                      onPressed: () => ref.read(executionProvider.notifier).clear(),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isLoading)
                       const Center(child: CircularProgressIndicator())
                    else if (execState.result != null) ...[
                      if (execState.result!.stdout.isNotEmpty)
                         Text(execState.result!.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (execState.result!.stderr.isNotEmpty)
                         Text(execState.result!.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                      if (execState.result!.error.isNotEmpty)
                         Text(execState.result!.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white24),
                      Text('Time: ${execState.result!.executionTime} | Mem: ${execState.result!.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]
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
