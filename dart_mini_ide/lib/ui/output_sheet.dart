import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../utils/theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;
  double _height = 60.0;
  final double _minHeight = 60.0;
  final double _maxHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executionProvider);

    ref.listen(executionProvider, (previous, next) {
      if (previous?.isRunning == true && next.isRunning == false) {
        if (!_isExpanded && (next.stdout.isNotEmpty || next.stderr.isNotEmpty)) {
          setState(() {
            _isExpanded = true;
            _height = 250.0;
          });
        }
      }
    });

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _height -= details.delta.dy;
          if (_height < _minHeight) _height = _minHeight;
          if (_height > _maxHeight) _height = _maxHeight;
          _isExpanded = _height > 100;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: _height,
        decoration: BoxDecoration(
          color: AppTheme.backgroundEnd,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Column(
          children: [
            // Handle and Header
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  _height = _isExpanded ? 250.0 : _minHeight;
                });
              },
              child: Container(
                color: Colors.transparent, // expand touch area
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.terminal, color: AppTheme.accentYellow, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Console Output',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (state.isRunning)
                              const Padding(
                                padding: EdgeInsets.only(left: 12),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            if (state.executionTime.isNotEmpty)
                              Text(
                                '\${state.executionTime}  ',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            if (state.memory.isNotEmpty)
                              Text(
                                '\${state.memory}  ',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            IconButton(
                              icon: const Icon(Icons.clear_all, size: 20, color: Colors.white54),
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
                  ],
                ),
              ),
            ),

            // Output Content
            if (_height > 100)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withValues(alpha: 0.3),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.stdout.isNotEmpty)
                          Text(
                            state.stdout,
                            style: const TextStyle(
                              color: AppTheme.successGreen,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (state.stderr.isNotEmpty)
                          Text(
                            state.stderr,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (state.stdout.isEmpty && state.stderr.isEmpty && !state.isRunning)
                          const Text(
                            'No output.',
                            style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic),
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
