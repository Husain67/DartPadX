import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    if (!execState.showOutput) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 10) {
            ref.read(executionProvider.notifier).clearOutput();
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: AppTheme.backgroundEnd,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(top: BorderSide(color: AppTheme.pillBorder, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        if (execState.metrics.isNotEmpty)
                          Text(execState.metrics, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: execState.isExecuting
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: execState.stdout,
                                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                              ),
                              if (execState.stdout.isNotEmpty && execState.stderr.isNotEmpty) const TextSpan(text: '\n'),
                              TextSpan(
                                text: execState.stderr,
                                style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 14),
                              ),
                            ],
                          ),
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
