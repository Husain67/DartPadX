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
  double _height = 200.0;
  final double _minHeight = 60.0;
  final double _maxHeight = 600.0;

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _height -= details.delta.dy;
          if (_height < _minHeight) _height = _minHeight;
          if (_height > _maxHeight) _height = _maxHeight;
        });
      },
      child: Container(
        height: _height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.backgroundEnd,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Console Output',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (execState.isExecuting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryAccent,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text('Time: \${execState.executionTime}s  ',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        if (execState.memory.isNotEmpty)
                          Text('Mem: \${execState.memory}KB  ',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
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
            // Output Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (execState.stdout.isNotEmpty)
                      Text(
                        execState.stdout,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    if (execState.stderr.isNotEmpty) ...[
                      if (execState.stdout.isNotEmpty) const SizedBox(height: 8),
                      Text(
                        execState.stderr,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (execState.stdout.isEmpty && execState.stderr.isEmpty && !execState.isExecuting)
                      const Text(
                        'No output yet. Run your code.',
                        style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
