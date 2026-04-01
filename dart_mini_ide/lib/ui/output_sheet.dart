import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/execution_provider.dart';
import '../utils/colors.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;
  final double _minHeight = 48.0;
  final double _maxHeight = 300.0;

  @override
  Widget build(BuildContext context) {
    ref.listen<ExecutionState>(executionProvider, (previous, next) {
      if (previous?.isExecuting == true && !next.isExecuting) {
        if (!_isExpanded) {
          setState(() {
            _isExpanded = true;
          });
        }
      }
    });

    final executionState = ref.watch(executionProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -10) {
            setState(() => _isExpanded = true);
          } else if (details.primaryDelta! > 10) {
            setState(() => _isExpanded = false);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? _maxHeight : _minHeight,
          decoration: const BoxDecoration(
            color: AppColors.outputSheetBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandle(context, ref),
              if (_isExpanded)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (executionState.isExecuting)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: AppColors.accentYellow),
                            ),
                          )
                        else ...[
                          if (executionState.error.isNotEmpty) ...[
                             Text(
                               'System Error:',
                               style: TextStyle(
                                   color: AppColors.outputStderr, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               executionState.error,
                               style: const TextStyle(
                                   color: AppColors.outputStderr, fontFamily: 'monospace'),
                             ),
                             const SizedBox(height: 16),
                          ],
                          if (executionState.stderr.isNotEmpty) ...[
                             Text(
                               'Standard Error:',
                               style: TextStyle(
                                   color: AppColors.outputStderr, fontWeight: FontWeight.bold),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               executionState.stderr,
                               style: const TextStyle(
                                   color: AppColors.outputStderr, fontFamily: 'monospace'),
                             ),
                             const SizedBox(height: 16),
                          ],
                          if (executionState.stdout.isNotEmpty) ...[
                            const Text(
                              'Standard Output:',
                              style: TextStyle(
                                  color: AppColors.outputStdout, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              executionState.stdout,
                              style: const TextStyle(
                                  color: AppColors.outputText, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (executionState.executionTime.isNotEmpty ||
                              executionState.memory.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Time: ${executionState.executionTime} | Memory: ${executionState.memory}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                          if (executionState.stdout.isEmpty &&
                              executionState.stderr.isEmpty &&
                              executionState.error.isEmpty &&
                              !executionState.isExecuting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No output yet. Run some code!', style: TextStyle(color: Colors.grey)),
                              ),
                            )
                        ],
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

  Widget _buildHandle(BuildContext context, WidgetRef ref) {
    return Container(
      height: _minHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Console',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
               if (_isExpanded)
                  IconButton(
                     icon: const Icon(Icons.delete_sweep, color: Colors.grey, size: 20),
                     onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                     },
                     tooltip: 'Clear Output',
                  ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}