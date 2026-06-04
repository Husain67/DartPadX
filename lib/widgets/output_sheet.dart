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

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);
    final stdin = ref.watch(stdinProvider);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -10) {
          setState(() => _isExpanded = true);
        } else if (details.primaryDelta! > 10) {
          setState(() => _isExpanded = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _isExpanded ? MediaQuery.of(context).size.height * 0.5 : 60,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          children: [
            // Handle
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                width: double.infinity,
                color: Colors.transparent, // expanded tap area
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  if (executionState.executionTime.isNotEmpty)
                    Text('${executionState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    children: [
                      if (_isExpanded)
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.grey, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clear(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  )
                ],
              ),
            ),

            if (_isExpanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // STDIN Input Field
                      TextField(
                        onChanged: (val) => ref.read(stdinProvider.notifier).state = val,
                        controller: TextEditingController(text: stdin)..selection = TextSelection.collapsed(offset: stdin.length),
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Standard Input (stdin)',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (executionState.isExecuting)
                                const Center(child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: Color(0xFFFACC15)),
                                )),
                              if (executionState.stdout.isNotEmpty)
                                Text(
                                  executionState.stdout,
                                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
                                ),
                              if (executionState.stderr.isNotEmpty)
                                Text(
                                  executionState.stderr,
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 14),
                                ),
                              if (executionState.error.isNotEmpty)
                                Text(
                                  executionState.error,
                                  style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'monospace', fontSize: 14),
                                ),
                              if (!executionState.isExecuting && executionState.stdout.isEmpty && executionState.stderr.isEmpty && executionState.error.isEmpty)
                                const Text(
                                  'Ready to run.',
                                  style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
