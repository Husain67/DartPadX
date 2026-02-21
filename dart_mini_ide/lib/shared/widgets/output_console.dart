import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';
import 'package:dart_mini_ide/features/execution/providers/execution_provider.dart';

class OutputConsole extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const OutputConsole({super.key, required this.scrollController});

  @override
  ConsumerState<OutputConsole> createState() => _OutputConsoleState();
}

class _OutputConsoleState extends ConsumerState<OutputConsole> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _stdinController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _stdinController = TextEditingController(text: ref.read(stdinProvider));
    _stdinController.addListener(() {
      ref.read(stdinProvider.notifier).state = _stdinController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
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
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Output'),
              Tab(text: 'Input (Stdin)'),
            ],
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Output
                executionState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : SingleChildScrollView(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (executionState.error != null)
                                Text(
                                  'Error:\n${executionState.error!}',
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                ),
                              if (executionState.stderr != null && executionState.stderr!.isNotEmpty)
                                Text(
                                  executionState.stderr!,
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                ),
                              if (executionState.stdout != null)
                                Text(
                                  executionState.stdout!,
                                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                                ),
                              if (executionState.executionTime != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Time: ${executionState.executionTime}ms',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                              if (!executionState.hasRun && executionState.error == null)
                                 const Text(
                                   'Ready to run...',
                                   style: TextStyle(color: Colors.grey),
                                 ),
                            ],
                          ),
                        ),
                      ),
                // Input
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Standard Input (stdin) for execution:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextField(
                          controller: _stdinController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter input data here...',
                            fillColor: Colors.black12,
                            filled: true,
                          ),
                          style: const TextStyle(fontFamily: 'monospace', color: Colors.white),
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
    );
  }
}
