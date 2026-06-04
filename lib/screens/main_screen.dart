import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../services/api_service.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: executionState.isExecuting ? null : () => _runCode(ref, context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: executionState.isExecuting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
          ),
        ),
        child: Column(
          children: [
            const ToolbarWidget(),
            if (fileState.files.isNotEmpty)
              _buildTabBar(ref, fileState),
            Expanded(
              child: activeFile != null
                  ? const CodeEditorWidget()
                  : const Center(
                      child: Text(
                        'No files open.\nCreate or import a file to start coding.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: const OutputSheet(),
    );
  }

  Widget _buildTabBar(WidgetRef ref, FileState fileState) {
    return Container(
      height: 40,
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1A1A1A) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _runCode(WidgetRef ref, BuildContext context) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.useDefaultOneCompiler
        ? compilerState.presets.firstWhere((p) => p.name.contains('OneCompiler'))
        : compilerState.activePreset ?? compilerState.presets.firstWhere((p) => p.name.contains('OneCompiler'));

    final stdin = ref.read(stdinProvider);

    ref.read(executionProvider.notifier).setExecuting(true);

    // Open output sheet if not already open (we don't strictly control it here, but typically user expands it)

    final result = await ApiService.executeCode(
      code: activeFile.content,
      stdin: stdin,
      preset: preset,
    );

    ref.read(executionProvider.notifier).setResult(
      stdout: result['stdout'] ?? '',
      stderr: result['stderr'] ?? '',
      error: result['error'] ?? '',
      executionTime: result['executionTime'] ?? '',
      memory: result['memory'] ?? '',
    );
  }
}
