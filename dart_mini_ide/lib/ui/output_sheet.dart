import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    // Auto expand on execution start
    ref.listen<ExecutionState>(executionProvider, (previous, next) {
        if (previous?.isExecuting == false && next.isExecuting == true) {
            _controller.animateTo(
              0.4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
        }
    });

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 30,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (execState.isExecuting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentYellow),
                        ),
                      )
                    else if (execState.executionTime.isNotEmpty)
                      Text(
                        '${execState.executionTime} ${execState.memory.isNotEmpty ? '| ${execState.memory}' : ''}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (execState.stdout.isNotEmpty)
                        SelectableText(
                          execState.stdout,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.outputStdout,
                            fontSize: 13,
                          ),
                        ),
                      if (execState.stderr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: SelectableText(
                            execState.stderr,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppTheme.outputStderr,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (execState.stdout.isEmpty && execState.stderr.isEmpty && !execState.isExecuting)
                        const Text(
                          'Ready.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
