import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme.dart';

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
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Column(
            children: [
              // Handle and Header
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), // balance
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        ref.read(executionProvider.notifier).setSheetVisible(false);
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (execState.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                      ))
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(execState.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                      if (execState.stderr.isNotEmpty)
                        Text(execState.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                      if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty) ...[
                        const Divider(color: Colors.grey),
                        Row(
                          children: [
                            if (execState.executionTime.isNotEmpty)
                              Text('Time: ${execState.executionTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 16),
                            if (execState.memory.isNotEmpty)
                              Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        )
                      ]
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
