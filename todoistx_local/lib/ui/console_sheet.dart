import 'package:flutter/material.dart';
import '../services/compiler_service.dart';
import 'theme.dart';

class ConsoleSheet extends StatelessWidget {
  final bool isRunning;
  final ExecutionResult? result;

  const ConsoleSheet({super.key, required this.isRunning, this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E), // Slightly lighter than background
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: Colors.white24, width: 1)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Console Output', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        if (result != null)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close sheet to simulate clear
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                          ),
                      ],
                    ),
                        IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (isRunning) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                        ),
                      ),
                      const Center(child: Text("Executing...", style: TextStyle(color: Colors.white70))),
                    ] else if (result != null) ...[
                      if (result!.stdout.isNotEmpty)
                        Text(result!.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (result!.stderr.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(result!.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                        ),
                      if (result!.stdout.isEmpty && result!.stderr.isEmpty)
                        const Text("Process exited with no output.", style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Time: ${result!.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          Text('Memory: ${result!.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
