import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../core/constants.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<ExecutionState>(executionProvider, (previous, next) {
      if (previous?.isRunning == true && !next.isRunning && !_isExpanded) {
        setState(() {
          _isExpanded = true;
        });
      }
    });

    final executionState = ref.watch(executionProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.4 : 60,
      decoration: BoxDecoration(
        color: AppConstants.bgColorEnd,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 255 * 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: AppConstants.accentColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Console Output',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (executionState.isRunning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.accentColor,
                      ),
                    )
                  else if (_isExpanded)
                    IconButton(
                      icon: const Icon(Icons.clear_all, color: Colors.white54),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                      tooltip: 'Clear Output',
                    )
                  else
                    const SizedBox(width: 24),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppConstants.bgColorStart,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (executionState.executionTime.isNotEmpty || executionState.memory.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Time: ${executionState.executionTime} | Mem: ${executionState.memory}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (executionState.stdout.isNotEmpty)
                        Text(
                          executionState.stdout,
                          style: const TextStyle(
                            color: AppConstants.successColor,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      if (executionState.stderr.isNotEmpty)
                        Text(
                          executionState.stderr,
                          style: const TextStyle(
                            color: AppConstants.errorColor,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      if (executionState.error.isNotEmpty)
                        Text(
                          executionState.error,
                          style: const TextStyle(
                            color: AppConstants.errorColor,
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (!executionState.isRunning &&
                          executionState.stdout.isEmpty &&
                          executionState.stderr.isEmpty &&
                          executionState.error.isEmpty)
                        const Text(
                          'No output generated.',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
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
