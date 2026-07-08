import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/compiler_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(ref),
          Expanded(
            child: state.isRunning
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                : _buildOutputArea(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Output Console',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white54),
            tooltip: 'Clear Output',
            onPressed: () => ref.read(compilerProvider.notifier).clearOutput(),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputArea(CompilerState state) {
    if (state.stdout.isEmpty && state.stderr.isEmpty) {
      return const Center(
        child: Text(
          'No output yet. Run your code!',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0A0A0A),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.stdout.isNotEmpty)
              Text(
                state.stdout,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.greenAccent,
                  fontSize: 14,
                ),
              ),
            if (state.stderr.isNotEmpty) ...[
              if (state.stdout.isNotEmpty) const SizedBox(height: 16),
              Text(
                state.stderr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            ],
            if (state.executionTime.isNotEmpty || state.memory.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              Row(
                children: [
                  if (state.executionTime.isNotEmpty)
                    Text('Time: ${state.executionTime}ms', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (state.executionTime.isNotEmpty && state.memory.isNotEmpty)
                    const SizedBox(width: 16),
                  if (state.memory.isNotEmpty)
                    Text('Memory: ${state.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
