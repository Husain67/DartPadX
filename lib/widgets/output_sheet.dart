import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';

class OutputSheet extends ConsumerStatefulWidget {
  const OutputSheet({super.key});

  @override
  ConsumerState<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends ConsumerState<OutputSheet> {
  final DraggableScrollableController _controller = DraggableScrollableController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(executionState),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(executionState),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        height: 5,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildHeader(ExecutionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Output Console',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryAccent,
            ),
          ),
          if (state.isRunning)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.clear_all, size: 20),
              color: AppTheme.textMuted,
              onPressed: () {
                ref.read(executionProvider.notifier).clearOutput();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContent(ExecutionState state) {
    if (state.isRunning) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Executing...', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    if (state.stdout.isEmpty && state.stderr.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No output yet.', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.executionTime.isNotEmpty || state.memory.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                if (state.executionTime.isNotEmpty)
                  _buildStatBadge(Icons.timer, '${state.executionTime}ms'),
                if (state.executionTime.isNotEmpty && state.memory.isNotEmpty)
                  const SizedBox(width: 8),
                if (state.memory.isNotEmpty)
                  _buildStatBadge(Icons.memory, state.memory),
              ],
            ),
          ),
        if (state.stdout.isNotEmpty)
          Text(
            state.stdout,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.greenAccent,
              fontSize: 14,
            ),
          ),
        if (state.stderr.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: state.stdout.isNotEmpty ? 16.0 : 0),
            child: Text(
              state.stderr,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
