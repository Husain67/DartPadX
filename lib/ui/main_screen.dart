// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'toolbar_widget.dart';
import 'editor_widget.dart';
import '../providers/file_notifier.dart';
import '../providers/compiler_notifier.dart';
import '../providers/execution_notifier.dart';
import '../services/execution_service.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          _RunButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ToolbarWidget(),
            const _FileTabs(),
            const Expanded(
              child: EditorWidget(),
            ),
          ],
        ),
      ),
      bottomSheet: const _OutputBottomSheet(),
    );
  }
}

class _RunButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return GestureDetector(
      onTap: execState.isLoading ? null : () async {
        final fileState = ref.read(filesProvider);
        if (fileState.activeFileId == null) return;

        final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);
        final compilerState = ref.read(compilerProvider);

        ref.read(executionProvider.notifier).setRunning();

        final result = await ExecutionService.runCode(
          preset: compilerState.activePreset,
          code: activeFile.content,
          stdin: "", // You could add a stdin tab/dialog here later
        );

        ref.read(executionProvider.notifier).setResult(
          stdout: result['stdout']!,
          stderr: result['stderr']!,
          time: result['time']!,
          memory: result['memory']!,
        );
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFACC15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (execState.isLoading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            else
              const Icon(Icons.play_arrow, color: Colors.black, size: 20),
            const SizedBox(width: 4),
            const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FileTabs extends ConsumerWidget {
  const _FileTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(filesProvider);

    return Container(
      height: 40,
      color: const Color(0xFF111111),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (ctx, i) {
          final file = fileState.files[i];
          final isActive = file.id == fileState.activeFileId;

          return GestureDetector(
            onTap: () => ref.read(filesProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF222222) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OutputBottomSheet extends ConsumerWidget {
  const _OutputBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(executionProvider);

    if (!state.isPanelOpen) {
      return GestureDetector(
        onTap: () => ref.read(executionProvider.notifier).togglePanel(),
        child: Container(
          height: 40,
          color: const Color(0xFF1a1a1a),
          alignment: Alignment.center,
          child: const Text('Tap to open output', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Container(
      height: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => ref.read(executionProvider.notifier).togglePanel(),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                if (state.time.isNotEmpty) Text('Time: ${state.time}s', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(width: 8),
                if (state.memory.isNotEmpty) Text('Mem: ${state.memory}KB', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                else if (state.stdout.isEmpty && state.stderr.isEmpty)
                  const Text('No output', style: TextStyle(color: Colors.white54))
                else ...[
                  if (state.stdout.isNotEmpty)
                    Text(state.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                  if (state.stderr.isNotEmpty)
                    Text(state.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
