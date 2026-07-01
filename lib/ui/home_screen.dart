import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import 'widgets/toolbar.dart';
import 'widgets/editor.dart';
import 'widgets/output_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _runCode(ref),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          // Manual trigger of save, though we auto-save. Could show a toast.
        },
      },
      child: Focus(
        autofocus: true,
        child: AppTheme.gradientBackground(
          Scaffold(
            appBar: _buildAppBar(),
            body: Stack(
              children: [
                Column(
                  children: [
                    const MainToolbar(),
                    _buildTabs(),
                    const Expanded(
                      child: CodeEditorWidget(),
                    ),
                  ],
                ),
                const OutputSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          const Text('DartMini'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'beta',
              style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
          child: Consumer(builder: (context, ref, child) {
            final compilerState = ref.watch(compilerProvider);
            return ElevatedButton.icon(
              onPressed: compilerState.isExecuting ? null : () => _runCode(ref),
              icon: compilerState.isExecuting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: const StadiumBorder(),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    final fileState = ref.watch(fileProvider);

    if (fileState.openFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.openFiles.length,
        itemBuilder: (context, index) {
          final file = fileState.openFiles[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundEnd : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.accentColor : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(fileProvider.notifier).setActiveFile(file.id);
                      ref.read(fileProvider.notifier).deleteActiveFile();
                    },
                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _runCode(WidgetRef ref) {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFileId == null) return;

    final activeFile = fileState.openFiles.firstWhere((f) => f.id == fileState.activeFileId);

    _promptForStdin(activeFile.content, activeFile.name, ref);
  }

  void _promptForStdin(String code, String filename, WidgetRef ref) {
    String stdinValue = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Provide standard input (optional)'),
          content: TextField(
            maxLines: 4,
            onChanged: (v) => stdinValue = v,
            decoration: const InputDecoration(
              hintText: 'Enter input for stdin...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(compilerProvider.notifier).executeCode(code, stdinValue, filename);
              },
              child: const Text('RUN'),
            ),
          ],
        );
      },
    );
  }
}
