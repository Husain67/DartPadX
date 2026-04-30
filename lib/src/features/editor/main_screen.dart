import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/files_provider.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';
import 'editor_toolbar.dart';
import 'file_tabs.dart';
import 'code_editor.dart';
import 'output_console.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref, executionState),
              const EditorToolbar(),
              const FileTabs(),
              const Expanded(
                child: Stack(
                  children: [
                    CodeEditor(),
                    OutputConsole(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, ExecutionState executionState) {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'DartMini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: executionState.isLoading
                ? null
                : () {
                    final filesState = ref.read(filesProvider);
                    if (filesState.activeFileId.isEmpty) return;
                    final activeFile = filesState.files.firstWhere((f) => f.id == filesState.activeFileId);
                    final stdin = ref.read(stdinProvider);
                    ref.read(executionProvider.notifier).executeCode(activeFile.content, stdin);
                  },
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  if (executionState.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  else
                    const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    'Run',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
