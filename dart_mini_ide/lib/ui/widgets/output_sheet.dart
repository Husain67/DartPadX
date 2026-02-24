import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(executionResultProvider);
    final isLoading = ref.watch(executionLoadingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1, // collapsed
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black54)],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFFFACC15)),
                ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: result == null && !isLoading
                      ? const Text('Run your code to see output.', style: TextStyle(color: Colors.grey))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (result?.stdout.isNotEmpty ?? false)
                              Text(result!.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                            if (result?.stderr.isNotEmpty ?? false)
                              Text(result!.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                            if (result?.error.isNotEmpty ?? false)
                              Text('Error: ${result!.error}', style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),

                            if ((result?.executionTime.isNotEmpty ?? false) || (result?.memory.isNotEmpty ?? false))
                               const Divider(color: Colors.grey),

                            if (result?.executionTime.isNotEmpty ?? false)
                               Text('Time: ${result!.executionTime} ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (result?.memory.isNotEmpty ?? false)
                               Text('Memory: ${result!.memory} KB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
