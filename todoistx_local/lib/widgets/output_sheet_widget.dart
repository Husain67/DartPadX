import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheetWidget extends ConsumerWidget {
  const OutputSheetWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);
    final notifier = ref.read(executionProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundStart,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            children: [
              // Handle & Header
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  // The drag behavior is handled by DraggableScrollableSheet,
                  // but we can add tap to toggle logic if we want.
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                         children: [
                            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 16),
                            const Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         ]
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => notifier.clearOutput(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => notifier.toggleOutput(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: state.isExecuting
                        ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryAccent)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.error != null)
                                 Text(state.error!, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                              if (state.stderr != null && state.stderr!.isNotEmpty)
                                 Text(state.stderr!, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                              if (state.stdout != null && state.stdout!.isNotEmpty)
                                 Text(state.stdout!, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                              if (state.stdout == null && state.stderr == null && state.error == null)
                                 const Text('No output', style: TextStyle(color: Colors.grey, fontFamily: 'monospace')),

                              const SizedBox(height: 16),
                              const Divider(color: Colors.grey),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (state.time != null) Text('Time: \${state.time}s', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  if (state.memory != null) Text('Memory: \${state.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              )
                            ],
                          ),
                  ),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
