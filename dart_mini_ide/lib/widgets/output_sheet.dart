import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: state.isPanelExpanded ? 0.4 : 0.05,
      minChildSize: 0.05,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            children: [
              // Handle
              GestureDetector(
                onTap: () {
                   ref.read(executionProvider.notifier).setPanelExpanded(!state.isPanelExpanded);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
              Expanded(
                child: state.isRunning
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                    : ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (state.executionTime != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text('Time: ${state.executionTime} | Mem: ${state.memory ?? "N/A"}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ),
                          if (state.stdout != null && state.stdout!.isNotEmpty)
                            Text(state.stdout!, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                          if (state.stderr != null && state.stderr!.isNotEmpty)
                            Text(state.stderr!, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                          if (state.error != null && state.error!.isNotEmpty)
                            Text(state.error!, style: const TextStyle(color: Colors.red, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                          if (state.stdout == null && state.stderr == null && state.error == null)
                            const Text("No output", style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
