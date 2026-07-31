import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state.dart';
import '../../core/theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  Color _getColorForType(String type) {
    switch (type) {
      case 'stdout': return Colors.greenAccent;
      case 'stderr': return Colors.redAccent;
      case 'error': return Colors.red;
      case 'meta': return Colors.yellow;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outputList = ref.watch(outputListProvider);
    final isVisible = ref.watch(showOutputProvider);
    final isExecuting = ref.watch(editorProvider).isExecuting;

    if (!isVisible) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              // Handle
              GestureDetector(
                onTap: () {
                  ref.read(showOutputProvider.notifier).state = false;
                },
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent, // expanded hit area
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
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

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        if (isExecuting)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAccent),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white70, size: 20),
                          onPressed: () {
                            ref.read(outputListProvider.notifier).state = [OutputData(text: 'Ready...')];
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                          onPressed: () {
                            ref.read(showOutputProvider.notifier).state = false;
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: outputList.length,
                    itemBuilder: (context, index) {
                      final out = outputList[index];
                      return Text(
                        out.text,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: _getColorForType(out.type),
                          fontSize: 13,
                        ),
                      );
                    },
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
