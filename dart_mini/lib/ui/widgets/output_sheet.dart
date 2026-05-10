import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../core/theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor2,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    const Text(
                      'Output Console',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        if (execState.isExecuting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          color: Colors.white54,
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Input field for Stdin
              Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                 child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Standard Input (stdin)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor)),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                 )
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      _buildOutputBlock(execState.stdout, Colors.greenAccent),
                    if (execState.stderr.isNotEmpty)
                      _buildOutputBlock(execState.stderr, Colors.redAccent),
                    if (execState.error.isNotEmpty)
                      _buildOutputBlock(execState.error, Colors.red),
                    if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          // ignore: prefer_interpolation_to_compose_strings
                          'Time: ' + (execState.executionTime.isEmpty ? '-' : execState.executionTime) + ' | Memory: ' + (execState.memory.isEmpty ? '-' : execState.memory),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildOutputBlock(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }
}
