import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartmini_ide/src/features/editor/providers/execution_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);
    final hasContent = executionState.output.isNotEmpty || executionState.error.isNotEmpty;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -10 && !_isExpanded) {
          setState(() => _isExpanded = true);
        } else if (details.primaryDelta! > 10 && _isExpanded) {
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? MediaQuery.of(context).size.height * 0.5 : (hasContent ? 150 : 50),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            )
          ],
        ),
        child: Column(
          children: [
            _buildHandle(context),
            Expanded(
              child: executionState.isRunning
                  ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (executionState.output.isNotEmpty)
                            Text(
                              executionState.output,
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                            ),
                          if (executionState.error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                executionState.error,
                                style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                              ),
                            ),
                          if (!hasContent && !executionState.isRunning)
                            const Center(
                              child: Text(
                                'Run code to see output',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          if (executionState.executionTime.isNotEmpty) ...[
                            const Divider(color: Colors.white24),
                            Text(
                              'Time: ${executionState.executionTime}ms | Mem: ${executionState.memory}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
}
