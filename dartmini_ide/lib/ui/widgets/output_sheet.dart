import 'package:flutter/material.dart';
import '../../services/compiler_service.dart';
import '../theme.dart';

class OutputSheet extends StatelessWidget {
  final ExecutionResult result;

  const OutputSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Console Output',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildBadge(Icons.timer, result.executionTime),
                const SizedBox(width: 12),
                _buildBadge(Icons.memory, result.memory),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (result.stdout.isNotEmpty)
                    Text(
                      result.stdout,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    ),
                  if (result.stderr.isNotEmpty) ...[
                    if (result.stdout.isNotEmpty) const SizedBox(height: 16),
                    Text(
                      result.stderr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                  if (result.error.isNotEmpty) ...[
                    if (result.stdout.isNotEmpty || result.stderr.isNotEmpty)
                      const SizedBox(height: 16),
                    Text(
                      result.error,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (result.stdout.isEmpty && result.stderr.isEmpty && result.error.isEmpty)
                    const Text(
                      'No output',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryAccent),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
