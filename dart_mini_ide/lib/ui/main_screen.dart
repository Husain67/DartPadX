import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';

import '../theme/app_theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'toolbar.dart';
import 'editor_tabs.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(() {
      ref.read(fileProvider.notifier).updateContent(_codeController.text);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final execState = ref.watch(executionProvider);

    // Sync editor with active file
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFile != null && next.activeFile!.content != _codeController.text) {
        final currentCursor = _codeController.selection;
        _codeController.text = next.activeFile!.content;

        // Basic attempt to preserve cursor position if possible
        if (currentCursor.baseOffset <= _codeController.text.length) {
          _codeController.selection = currentCursor;
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
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
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting ? null : () {
                 final activeFile = ref.read(fileProvider).activeFile;
                 if (activeFile != null) {
                    ref.read(executionProvider.notifier).executeCode(activeFile.content);
                 }
              },
              icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(execState.isExecuting ? 'Running' : 'Run'),
              style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppConstants.maxMobileWidth),
                child: Column(
                  children: [
                    const EditorToolbar(),
                    const EditorTabs(),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            color: AppTheme.editorBg,
                            child: CodeTheme(
                              data: CodeThemeData(styles: atomOneDarkTheme),
                              child: SingleChildScrollView(
                                child: CodeField(
                                  controller: _codeController,
                                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                                  gutterStyle: const GutterStyle(
                                      textStyle: TextStyle(
                                          color: AppTheme.gutterText,
                                          height: 1.5,
                                          fontFamily: 'monospace',
                                      ),
                                      showLineNumbers: true,
                                      margin: 8.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: OutputSheet(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        ),
      ),
    );
  }
}
