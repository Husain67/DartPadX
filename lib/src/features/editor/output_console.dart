import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';

class OutputConsole extends ConsumerWidget {
  const OutputConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (executionState.executionTime.isNotEmpty)
                       Text(
                         'Time: ${executionState.executionTime}',
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                       ),
                    const SizedBox(width: 8),
                    if (executionState.memory.isNotEmpty)
                       Text(
                         'Mem: ${executionState.memory}',
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                       ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                    )
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Stdin input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    hintStyle: TextStyle(color: Colors.white30),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    ref.read(stdinProvider.notifier).state = val;
                  },
                ),
              ),
               const Divider(height: 1, color: Colors.grey),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (executionState.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppTheme.accentYellow),
                        ),
                      )
                    else if (executionState.stdout.isEmpty && executionState.stderr.isEmpty)
                      const Text(
                        'Ready.',
                        style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                      )
                    else ...[
                      if (executionState.stdout.isNotEmpty)
                        Text(
                          executionState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                        ),
                      if (executionState.stderr.isNotEmpty)
                        Text(
                          executionState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                        ),
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
