import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  final DraggableScrollableController _dragController = DraggableScrollableController();
  bool _hasAutoExpanded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(executionProvider, (prev, next) {
      if (prev?.isExecuting == true && next.isExecuting == false) {
        if (!_hasAutoExpanded) {
          _dragController.animateTo(
            0.4,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          _hasAutoExpanded = true;
        }
      } else if (next.isExecuting) {
        _hasAutoExpanded = false;
      }
    });

    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      controller: _dragController,
      initialChildSize: 0.20,
      minChildSize: 0.20,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              GestureDetector(
                onVerticalDragUpdate: (details) {
                   // Let DraggableScrollableSheet handle it natively via its scrollController
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty) ...[
                          Text(execState.executionTime, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (execState.memory.isNotEmpty) ...[
                          Text(execState.memory, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
                          onPressed: () {
                            ref.read(executionProvider.notifier).clear();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              // Output Area
              Flexible(
                child: execState.isExecuting
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                            const Text('No output.', style: TextStyle(color: Colors.white30, fontFamily: 'monospace')),
                          if (execState.stdout.isNotEmpty)
                            Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                          if (execState.stderr.isNotEmpty)
                            Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
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
