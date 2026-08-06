import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputConsole extends ConsumerWidget {
  const OutputConsole({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    if (!state.showOutput) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
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
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (state.time.isNotEmpty)
                      Text('Time: ${state.time}ms ', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    if (state.memory.isNotEmpty)
                      Text('Mem: ${state.memory}KB ', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).hideOutput(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.isRunning)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                        ),
                      )
                    else ...[
                      if (state.stdout.isNotEmpty)
                        Text(
                          state.stdout,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.greenAccent,
                          ),
                        ),
                      if (state.stderr.isNotEmpty)
                        Text(
                          state.stderr,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.redAccent,
                          ),
                        ),
                      if (state.stdout.isEmpty && state.stderr.isEmpty)
                        const Text(
                          'No output.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white54,
                          ),
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
