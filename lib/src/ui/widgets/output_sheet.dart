import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../screens/main_screen.dart';

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
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
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
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text('${execState.executionTime} ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (execState.memory.isNotEmpty)
                          Text('| ${execState.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                          tooltip: 'Clear Output',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Input Field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Standard Input (stdin)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                ),
              ),
              // Output Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (execState.stdout.isNotEmpty)
                          Text(
                            execState.stdout,
                            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                          ),
                        if (execState.stderr.isNotEmpty) ...[
                          if (execState.stdout.isNotEmpty) const SizedBox(height: 8),
                          Text(
                            execState.stderr,
                            style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 13),
                          ),
                        ],
                      ],
                    ),
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
