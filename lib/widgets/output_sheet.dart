import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/all_providers.dart';
import '../utils/theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (execState.isRunning)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.primaryAccent, strokeWidth: 2))
                    else
                      Row(
                        children: [
                          if (execState.executionTime.isNotEmpty) Text('⏱ ${execState.executionTime}  ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          if (execState.memory.isNotEmpty) Text('💾 ${execState.memory}  ', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20, color: Colors.white54),
                            onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                          )
                        ],
                      )
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(execState.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                    if (execState.stderr.isNotEmpty)
                      Text(execState.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                    if (execState.error.isNotEmpty)
                      Text(execState.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty && execState.error.isEmpty && !execState.isRunning)
                      const Text('No output yet. Run your code.', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
