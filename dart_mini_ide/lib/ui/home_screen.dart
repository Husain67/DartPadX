import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/execution_provider.dart';
import '../providers/file_provider.dart';
import 'toolbar.dart';
import 'editor_area.dart';
import 'output_sheet.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBackgroundTop, AppTheme.darkBackgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, ref, execState, fileState),
                  const EditorToolbar(),
                  const Expanded(child: EditorArea()),
                ],
              ),
              if (execState.stdout != null || execState.stderr != null || execState.error != null || execState.isRunning)
                const OutputSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, ExecutionState execState, FileState fileState) {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'DartMini',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: execState.isRunning ? null : () {
              if (fileState.activeFile != null) {
                ref.read(executionProvider.notifier).runCode(fileState.activeFile!.content);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: execState.isRunning
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : const Icon(Icons.play_arrow, size: 20, color: Colors.black),
            label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
