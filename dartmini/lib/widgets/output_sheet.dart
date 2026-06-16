import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.white54, size: 20),
                    SizedBox(width: 8),
                    Text('Output Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(executionProvider);

                    if (state.isRunning) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFFACC15)),
                            SizedBox(height: 16),
                            Text('Executing...', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (state.stdout.isNotEmpty) ...const [
                          Text('stdout', style: TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
                        if (state.stdout.isNotEmpty) ...[
                          Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                          const SizedBox(height: 16),
                        ],
                        if (state.stderr.isNotEmpty) ...const [
                          Text('stderr', style: TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
                        if (state.stderr.isNotEmpty) ...[
                          Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                          const SizedBox(height: 16),
                        ],
                        if (state.executionTime.isNotEmpty || state.memory.isNotEmpty)
                          Row(
                            children: [
                              if (state.executionTime.isNotEmpty)
                                Text('Time: \${state.executionTime}ms', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(width: 16),
                              if (state.memory.isNotEmpty)
                                Text('Memory: \${state.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        if (state.stdout.isEmpty && state.stderr.isEmpty && !state.isRunning)
                          const Text('No output yet', style: TextStyle(color: Colors.white30, fontStyle: FontStyle.italic)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox();
  }
}
