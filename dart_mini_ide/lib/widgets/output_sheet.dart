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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -10) {
          setState(() {
            _isExpanded = true;
          });
        } else if (details.delta.dy > 10) {
          setState(() {
            _isExpanded = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? MediaQuery.of(context).size.height * 0.4 : 60,
        decoration: BoxDecoration(
          color: AppTheme.pureBlack,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      if (execState.isExecuting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                          ),
                        ),
                      if (_isExpanded && (execState.stdout.isNotEmpty || execState.stderr.isNotEmpty || execState.error.isNotEmpty))
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white54, size: 20),
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
            if (_isExpanded)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (execState.error.isNotEmpty)
                        Text(
                          execState.error,
                          style: const TextStyle(color: Colors.red, fontFamily: 'monospace'),
                        ),
                      if (execState.stderr.isNotEmpty)
                        Text(
                          execState.stderr,
                          style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                        ),
                      if (execState.stdout.isNotEmpty)
                        Text(
                          execState.stdout,
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                        ),
                      if (execState.time.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Execution Time: ${execState.time}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                      if (execState.memory.isNotEmpty)
                        Text(
                          'Memory: ${execState.memory}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
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
