import 'package:flutter/material.dart';
import '../services/compiler_api.dart';
import '../theme.dart';

class OutputBottomSheet extends StatelessWidget {
  final ExecutionResult result;
  final bool isLoading;

  const OutputBottomSheet({
    super.key,
    required this.result,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.gradientEnd,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Output Console',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          else ...[
            if (result.stdout.isNotEmpty) ...[
              const Text('STDOUT:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.stdout,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (result.stderr.isNotEmpty || result.error.isNotEmpty) ...[
              const Text('STDERR / ERROR:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.stderr.isNotEmpty ? result.stderr : result.error,
                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: \${result.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text('Memory: \${result.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

void showOutputSheet(BuildContext context, ExecutionResult result, {bool isLoading = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => OutputBottomSheet(result: result, isLoading: isLoading),
  );
}
