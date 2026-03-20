import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  bool _isExpanded = false;
  bool _wasRunning = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executionProvider);
    final hasOutput = state.stdout.isNotEmpty || state.stderr.isNotEmpty;

    // Automatically expand if there's new output and it's not currently running, but it was just running
    if (!state.isRunning && _wasRunning && hasOutput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {
          _isExpanded = true;
          _wasRunning = false;
        });
      });
    } else if (state.isRunning && !_wasRunning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {
                _wasRunning = true;
                _isExpanded = true;
            });
        });
    } else if (!state.isRunning && _wasRunning) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {
                _wasRunning = false;
            });
        });
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.4 : 48,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.terminal, color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  const Text('Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (state.isRunning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFACC15)),
                    ),
                  if (!state.isRunning && state.executionTime.isNotEmpty)
                    Text('${state.executionTime} • ${state.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white54),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.stdout.isNotEmpty)
                            Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14)),
                          if (state.stderr.isNotEmpty)
                            Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 14)),
                          if (state.stdout.isEmpty && state.stderr.isEmpty && !state.isRunning)
                            const Text('No output', style: TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white54),
                      tooltip: 'Clear Output',
                      onPressed: () {
                        ref.read(executionProvider.notifier).clearOutput();
                      },
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
