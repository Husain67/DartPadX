import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.7 : 120.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              color: Colors.transparent, // Expand tap area
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Output Console',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    if (execState.executionTime.isNotEmpty) ...[
                      const Icon(Icons.timer, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(execState.executionTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (execState.memory.isNotEmpty) ...[
                      const Icon(Icons.memory, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(execState.memory, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.grey, size: 20),
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
                      tooltip: 'Clear Output',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey, height: 1),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (execState.isRunning)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                        ),
                      )
                    else if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Text(
                        'No output yet. Run your code!',
                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                      )
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(
                          execState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                        ),
                      if (execState.stderr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            execState.stderr,
                            style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 13),
                          ),
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
  }
}
