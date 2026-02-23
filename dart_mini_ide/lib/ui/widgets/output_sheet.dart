import 'package:dart_mini_ide/providers/execution_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OutputSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const OutputSheet({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);
    final result = state.result;

    if (state.isExecuting) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: const [
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Colors.yellow),
                SizedBox(height: 16),
                Text("Executing Code...", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      );
    }

    if (result == null) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        children: const [
          Center(
            child: Text(
              "Output will appear here",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        if (result.executionTime != null || result.memory != null)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (result.executionTime != null)
                  _buildMetric("Time", result.executionTime!),
                if (result.memory != null)
                  _buildMetric("Memory", result.memory!),
              ],
            ),
          ),

        if (result.stdout.isNotEmpty) ...[
          const Text("Output:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(
            result.stdout,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (result.stderr.isNotEmpty) ...[
          const Text("Error Output:", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(
            result.stderr,
            style: const TextStyle(
              color: Colors.redAccent,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (result.error != null && result.error!.isNotEmpty) ...[
          const Text("System Error:", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(
            result.error!,
            style: const TextStyle(
              color: Colors.red,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
