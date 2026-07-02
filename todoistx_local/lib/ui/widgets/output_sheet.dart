import 'package:flutter/material.dart';
import '../../services/compiler_service.dart';

class OutputSheet extends StatefulWidget {
  final ExecutionResult? result;
  final bool isRunning;
  final String? error;

  const OutputSheet({
    super.key,
    this.result,
    required this.isRunning,
    this.error,
  });

  @override
  State<OutputSheet> createState() => _OutputSheetState();
}

class _OutputSheetState extends State<OutputSheet> {
  bool _cleared = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Console Output',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.grey),
                tooltip: 'Clear Output',
                onPressed: () {
                  setState(() {
                    _cleared = true;
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isRunning) {
      _cleared = false;
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFFACC15)),
        ),
      );
    }

    if (_cleared) {
       return const Text(
        'Output cleared.',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    if (widget.error != null) {
      return Text(
        widget.error!,
        style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
      );
    }

    if (widget.result == null) {
      return const Text(
        'Run code to see output here...',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.result!.stdout.isNotEmpty)
          Text(
            widget.result!.stdout,
            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
          ),
        if (widget.result!.stderr.isNotEmpty) ...[
          if (widget.result!.stdout.isNotEmpty) const SizedBox(height: 8),
          Text(
            widget.result!.stderr,
            style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
          ),
        ],
        if (widget.result!.executionTime.isNotEmpty || widget.result!.memory.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          Row(
            children: [
              if (widget.result!.executionTime.isNotEmpty)
                Text(
                  'Time: ${widget.result!.executionTime}s',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              if (widget.result!.executionTime.isNotEmpty && widget.result!.memory.isNotEmpty)
                const SizedBox(width: 16),
              if (widget.result!.memory.isNotEmpty)
                Text(
                  'Memory: ${widget.result!.memory}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ]
      ],
    );
  }
}
