import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../utils/constants.dart';

class ConsoleSheet extends ConsumerWidget {
  const ConsoleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);
    final result = compilerState.result;

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Output',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    if (compilerState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryAccent)
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: compilerState.isLoading
                    ? const Center(child: Text("Running...", style: TextStyle(color: Colors.white54)))
                    : result == null
                        ? const Center(child: Text("No output", style: TextStyle(color: Colors.white24)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (result.isError)
                                const Text("Execution Failed", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                              if (result.stdout.isNotEmpty)
                                SelectableText(result.stdout, style: const TextStyle(color: AppColors.success, fontFamily: 'monospace')),
                              if (result.stderr.isNotEmpty)
                                SelectableText(result.stderr, style: const TextStyle(color: AppColors.error, fontFamily: 'monospace')),
                              const SizedBox(height: 16),
                              if (result.executionTime.isNotEmpty)
                                Text(
                                  'Execution Time: ${result.executionTime}',
                                  style: const TextStyle(color: Colors.white30, fontSize: 12),
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
