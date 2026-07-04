import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_notifier.dart';

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
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_controller != null) {
      ref.read(filesProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(filesProvider);

    if (fileState.activeFileId == null || fileState.files.isEmpty) {
      return const Center(
        child: Text(
          'No active file. Create or import one.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);

    if (_activeFileId != activeFile.id) {
      _activeFileId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content) {
      // Sync external changes like format and paste to the controller
      final currentSelection = _controller!.selection;
      _controller!.text = activeFile.content;

      // Attempt to preserve cursor position
      final newOffset = currentSelection.baseOffset > activeFile.content.length
          ? activeFile.content.length
          : currentSelection.baseOffset;

      _controller!.selection = TextSelection.collapsed(offset: newOffset);
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white54, height: 1.5),
          ),
        ),
      ),
    );
  }
}
