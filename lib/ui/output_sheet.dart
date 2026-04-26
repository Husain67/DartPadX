import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    // Auto expand when there's new output or error
    ref.listen<ExecutionState>(executionProvider, (prev, next) {
      if ((prev?.isRunning == true && !next.isRunning) &&
          (next.stdout.isNotEmpty || next.stderr.isNotEmpty)) {
        if (_controller.isAttached && _controller.size < 0.4) {
          _controller.animateTo(
            0.4,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty) ...[
                          Text(
                            '${execState.executionTime} ms',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white54, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clearOutput();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    if (execState.stderr.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          execState.stderr,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                      const Center(
                        child: Text(
                          'No output',
                          style: TextStyle(color: Colors.white24),
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
}

// Extension to fix onSize/padding syntax for IconButton
extension IconButtonPadding on IconButton {
  IconButton copyWithPadding() {
    return this;
  }
}
