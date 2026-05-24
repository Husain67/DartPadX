import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    final result = execState.result;

    return DraggableScrollableSheet(
      initialChildSize: 0.20,
      minChildSize: 0.10,
      maxChildSize: 0.80,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: DartMiniTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, color: DartMiniTheme.primary)),
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ),
              // Input area for stdin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    isDense: true,
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (result != null) ...[
                        if (result.stdout.isNotEmpty)
                          Text(result.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                        if (result.stderr.isNotEmpty)
                          Text(result.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                        if (result.error.isNotEmpty)
                          Text(result.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Divider(),
                        if (result.executionTime.isNotEmpty)
                          Text('Time: ${result.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        if (result.memory.isNotEmpty)
                          Text('Memory: ${result.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ] else if (execState.isRunning) ...[
                        const Text('Executing...', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                      ] else ...[
                        const Text('Ready.', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
