import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  final TextEditingController _stdinController = TextEditingController();

  @override
  void dispose() {
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                      tooltip: 'Clear Output',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).toggleOutput(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Stdin input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _stdinController,
              decoration: const InputDecoration(
                hintText: 'Standard Input (stdin)...',
                isDense: true,
              ),
              onChanged: (val) => ref.read(executionProvider.notifier).setStdin(val),
              maxLines: 2,
            ),
          ),

          // Output Area
          Expanded(
            child: execState.isExecuting
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (execState.result != null) ...[
                          if (execState.result!.stdout.isNotEmpty)
                            Text(execState.result!.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),

                          if (execState.result!.stderr.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(execState.result!.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                            ),

                          if (execState.result!.error.isNotEmpty)
                             Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(execState.result!.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                            ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('Time: ${execState.result!.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 16),
                              if (execState.result!.memory.isNotEmpty)
                                Text('Memory: ${execState.result!.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          )
                        ] else ...[
                           const Text('Run code to see output here.', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
