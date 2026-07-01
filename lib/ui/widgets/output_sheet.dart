import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/compiler_provider.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  double _height = 200.0;
  final double _minHeight = 60.0;
  final double _maxHeight = 600.0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    if (!state.isOutputSheetVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _height -= details.delta.dy;
            if (_height < _minHeight) _height = _minHeight;
            if (_height > _maxHeight) _height = _maxHeight;
          });
        },
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Output Console',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear_all, size: 20),
                          onPressed: () {
                            ref.read(compilerProvider.notifier).clearOutput();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            ref.read(compilerProvider.notifier).toggleOutputSheet(false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Content
              Expanded(
                child: _buildContent(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(CompilerState state) {
    if (state.isExecuting) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentColor),
      );
    }

    if ((state.stdout?.isEmpty ?? true) && (state.stderr?.isEmpty ?? true) && (state.error?.isEmpty ?? true)) {
      return const Center(
        child: Text(
          "Ready.\nRun code to see output.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.executionTime?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Time: ${state.executionTime} | Mem: ${state.memory ?? "N/A"}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          if (state.stdout?.isNotEmpty ?? false)
            Text(
              state.stdout!,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.greenAccent,
                fontSize: 14,
              ),
            ),
          if (state.stderr?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                state.stderr!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.redAccent,
                  fontSize: 14,
                ),
              ),
            ),
          if (state.error?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Exception: ${state.error!}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.orangeAccent,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
