import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/providers/execution_provider.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundEnd,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: AppTheme.primaryYellow,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primaryYellow,
                        tabs: [
                          Tab(text: 'Output'),
                          Tab(text: 'Input (stdin)'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Output Tab
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                                    ),
                                  ],
                                ),
                                if (execState.isRunning)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: AppTheme.primaryYellow),
                                    ),
                                  )
                                else if (execState.result != null) ...[
                                  if (execState.result!.stdout.isNotEmpty)
                                    Text(
                                      execState.result!.stdout,
                                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                                    ),
                                  if (execState.result!.stderr.isNotEmpty)
                                    Text(
                                      execState.result!.stderr,
                                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                    ),
                                  if (execState.result!.error.isNotEmpty)
                                    Text(
                                      execState.result!.error,
                                      style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Time: ${execState.result!.executionTime.isEmpty ? "N/A" : "${execState.result!.executionTime}s"} | Memory: ${execState.result!.memory.isEmpty ? "N/A" : execState.result!.memory}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ] else
                                  const Text(
                                    'No output yet. Run your code!',
                                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            // Input Tab
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Provide stdin inputs here (one per line):', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: execState.stdinInput,
                                      onChanged: (val) => ref.read(executionProvider.notifier).setStdin(val),
                                      maxLines: null,
                                      expands: true,
                                      style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Colors.black26,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
