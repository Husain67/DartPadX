import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../../data/providers/app_state.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({Key? key}) : super(key: key);

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  CodeController? _controller;
  String? _activeFileId;
  bool _isUpdatingFromState = false;

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
    if (_isUpdatingFromState) return;
    ref.read(editorProvider.notifier).updateActiveFileContent(_controller!.text);
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final activeFile = editorState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text('No file opened', style: TextStyle(color: Colors.white54)));
    }

    // Initialize or recreate controller if active file changes
    if (_controller == null || _activeFileId != activeFile.id) {
      _activeFileId = activeFile.id;
      _initController(activeFile.content);
    } else {
      // Sync text if it was updated externally (e.g. paste from toolbar, format)
      if (_controller!.text != activeFile.content) {
        _isUpdatingFromState = true;
        final currentSelection = _controller!.selection;
        _controller!.text = activeFile.content;

        // Try to maintain selection if possible
        if (currentSelection.baseOffset <= activeFile.content.length) {
          _controller!.selection = currentSelection;
        }

        _isUpdatingFromState = false;
      }
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: GutterStyle(
            textStyle: const TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
            ),
            width: 48,
          ),
          wrap: false,
        ),
      ),
    );
  }
}
