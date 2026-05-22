import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/app_state.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

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
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [

                        if (execState.executionTime.isNotEmpty) ...[
                          Text('${execState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (execState.memory.isNotEmpty) ...[
                          Text(execState.memory, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],

                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clear(),
                          tooltip: 'Clear Output',
                          color: Colors.grey,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black),
              // Content
              Expanded(
                child: execState.isExecuting
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.stdout.isEmpty && execState.stderr.isEmpty && execState.error.isEmpty)
                             const Text('No output yet. Run some code!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

                          if (execState.stdout.isNotEmpty)
                            Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),

                          if (execState.stderr.isNotEmpty) ...[
                            if (execState.stdout.isNotEmpty) const SizedBox(height: 8),
                            Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                          ],

                          if (execState.error.isNotEmpty) ...[
                            if (execState.stdout.isNotEmpty || execState.stderr.isNotEmpty) const SizedBox(height: 8),
                            Text(execState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
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
