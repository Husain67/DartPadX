import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../core/theme.dart';
import '../../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String? _activeFileId;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );

    _controller!.addListener(() {
      if (_controller!.text != ref.read(fileProvider).activeFile?.content) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(fileProvider.select((state) => state.activeFile));

    if (activeFile == null) {
      return const Center(
        child: Text('No active file', style: TextStyle(color: AppTheme.textMuted)),
      );
    }

    if (_activeFileId != activeFile.id) {
      _activeFileId = activeFile.id;
      _initController(activeFile.content);
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: const Color(0xFF2B2B2B), // darcula background
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller!,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              showLineNumbers: true,
              showErrors: false,
              showFoldingHandles: false,
            ),
          ),
        ),
      ),
    );
  }
}
