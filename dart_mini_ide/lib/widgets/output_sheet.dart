import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme.dart';

class OutputSheetWidget extends ConsumerStatefulWidget {
  const OutputSheetWidget({super.key});

  @override
  ConsumerState<OutputSheetWidget> createState() => _OutputSheetWidgetState();
}

class _OutputSheetWidgetState extends ConsumerState<OutputSheetWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(executionProvider);

    if (state.isRunning || state.stdout.isNotEmpty || state.stderr.isNotEmpty) {
      if (!state.isRunning && !_isExpanded && (state.stdout.isNotEmpty || state.stderr.isNotEmpty)) {
        // Auto expand only once per run finish
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() { _isExpanded = true; });
        });
      }
    } else {
      if (_isExpanded) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() { _isExpanded = false; });
        });
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? MediaQuery.of(context).size.height * 0.4 : 60,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 30,
              width: double.infinity,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Console Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (state.executionTime.isNotEmpty)
                      Text('${state.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 8),
                    if (state.memory.isNotEmpty)
                      Text('${state.memory}MB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                      onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                    )
                  ],
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.isRunning)
                        const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow)),
                      if (state.stdout.isNotEmpty)
                        Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (state.stderr.isNotEmpty)
                        Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
