import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheetWidget extends ConsumerStatefulWidget {
  const OutputSheetWidget({super.key});

  @override
  ConsumerState<OutputSheetWidget> createState() => _OutputSheetWidgetState();
}

class _OutputSheetWidgetState extends ConsumerState<OutputSheetWidget> {
  double _sheetHeight = 250.0;
  final double _minHeight = 80.0;
  final double _maxHeight = 600.0; // Could bound based on screen size

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return Container(
      height: _sheetHeight,
      decoration: BoxDecoration(
        color: AppTheme.backgroundEnd,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
          // Draggable Handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _sheetHeight -= details.delta.dy;
                if (_sheetHeight < _minHeight) _sheetHeight = _minHeight;
                if (_sheetHeight > _maxHeight) _sheetHeight = _maxHeight;
              });
            },
            child: Container(
              height: 30,
              color: Colors.transparent, // Expand touch target
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // Output Header Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Console Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    if (execState.isRunning) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAccent)),
                    if (execState.isRunning) const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.white54, size: 20),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                      tooltip: 'Clear Console',
                    )
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Metrics Area
          if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  if (execState.executionTime.isNotEmpty) Text('Time: \${execState.executionTime}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  if (execState.executionTime.isNotEmpty && execState.memory.isNotEmpty) const SizedBox(width: 16),
                  if (execState.memory.isNotEmpty) Text('Memory: \${execState.memory}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                ],
              ),
            ),
          // Scrollable Console Text
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (execState.isRunning) const Text('Executing...', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                  if (execState.stdout.isNotEmpty) Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                  if (execState.stderr.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'))),
                  if (!execState.isRunning && execState.stdout.isEmpty && execState.stderr.isEmpty) const Text('Ready.', style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
