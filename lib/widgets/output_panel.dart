// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class OutputPanel extends ConsumerStatefulWidget {
  const OutputPanel({super.key});

  @override
  ConsumerState<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends ConsumerState<OutputPanel> {
  double _height = 60.0;
  final double _minHeight = 60.0;
  final double _maxHeight = 400.0;
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      _height = _isExpanded ? _maxHeight / 2 : _minHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _height -= details.delta.dy;
          if (_height < _minHeight) _height = _minHeight;
          if (_height > _maxHeight) _height = _maxHeight;
          _isExpanded = _height > _minHeight;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: _height,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _toggleExpand,
              child: Container(
                height: 30,
                color: Colors.transparent,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                    onPressed: () {
                      ref.read(executionProvider.notifier).clear();
                    },
                  )
                ],
              ),
            ),
            if (_height > _minHeight + 20)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (execState.isRunning)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                      else ...[
                        if (execState.stdout.isNotEmpty)
                          Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                        if (execState.stderr.isNotEmpty)
                          Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                        if (execState.error.isNotEmpty)
                          Text(execState.error, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                        if (execState.time.isNotEmpty || execState.memory.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Time: \${execState.time}ms | Memory: \${execState.memory}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          )
                      ]
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
