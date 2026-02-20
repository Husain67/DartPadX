import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/execution_provider.dart';
import '../../core/constants.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(executionResultProvider);
    final isExecuting = ref.watch(isExecutingProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.08,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                           const Text(
                             "Console Output",
                             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                           ),
                           const Spacer(),
                           if (isExecuting)
                             const SizedBox(
                               width: 16, height: 16,
                               child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryColor),
                             ),
                         ],
                       ),
                       const SizedBox(height: 16),
                       if (result != null) ...[
                          if (result.stdout.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              color: Colors.black.withOpacity(0.3),
                              child: Text(result.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                            ),
                          if (result.stderr.isNotEmpty)
                             Container(
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              color: Colors.black.withOpacity(0.3),
                              child: Text(result.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                            ),
                          if (result.error.isNotEmpty)
                            Text("Error: ${result.error}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),

                          const Divider(color: Colors.grey),
                          Text("Execution Time: ${result.executionTime}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("Memory: ${result.memory}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                       ] else if (!isExecuting)
                          const Text("Ready to run.", style: TextStyle(color: Colors.grey)),
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
