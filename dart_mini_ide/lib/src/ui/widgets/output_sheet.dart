import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/execution_provider.dart';
import '../theme/theme_constants.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  double _sheetHeight = 300.0;
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _sheetHeight = _isExpanded ? MediaQuery.of(context).size.height * 0.8 : 300.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _sheetHeight -= details.delta.dy;
          if (_sheetHeight < 100) _sheetHeight = 100;
          if (_sheetHeight > MediaQuery.of(context).size.height * 0.9) {
            _sheetHeight = MediaQuery.of(context).size.height * 0.9;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _sheetHeight,
        decoration: const BoxDecoration(
          color: ThemeConstants.backgroundEnd,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle and Header
            GestureDetector(
              onTap: _toggleExpand,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Console Output',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.clear_all, color: Colors.white70),
                              onPressed: () {
                                ref.read(executionProvider.notifier).clearOutput();
                              },
                              tooltip: 'Clear',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                ref.read(executionProvider.notifier).hideOutput();
                              },
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Output Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: executionState.isExecuting
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 20),
                              CircularProgressIndicator(color: ThemeConstants.primaryAccent),
                              SizedBox(height: 16),
                              Text("Executing code...", style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (executionState.executionTime.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'Execution Time: ${executionState.executionTime} ms' +
                                      (executionState.memory.isNotEmpty ? ' | Memory: ${executionState.memory}' : ''),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            if (executionState.stdout.isNotEmpty)
                              Text(
                                executionState.stdout,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                              ),
                            if (executionState.stderr.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  executionState.stderr,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            if (executionState.error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  executionState.error,
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (executionState.stdout.isEmpty &&
                                executionState.stderr.isEmpty &&
                                executionState.error.isEmpty)
                              const Text(
                                'No output generated.',
                                style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
