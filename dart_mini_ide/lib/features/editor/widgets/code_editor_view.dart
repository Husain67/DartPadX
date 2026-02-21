import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';
import 'package:dart_mini_ide/features/editor/providers/editor_provider.dart';

class CodeEditorView extends ConsumerStatefulWidget {
  const CodeEditorView({super.key});

  @override
  ConsumerState<CodeEditorView> createState() => _CodeEditorViewState();
}

class _CodeEditorViewState extends ConsumerState<CodeEditorView> {
  CodeController? _controller;
  String? _currentFileId;

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
    _controller!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentFileId != null && _controller != null) {
      final content = _controller!.text;
      final activeFile = ref.read(editorProvider).activeFile;
      // Only update if changed to avoid unnecessary rebuilds if this triggered by state update
      if (activeFile != null && activeFile.content != content) {
         ref.read(editorProvider.notifier).updateFileContent(_currentFileId!, content);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);

    if (editorState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final activeFile = editorState.activeFile;
    if (activeFile == null) {
      return const Center(child: Text('No file open', style: TextStyle(color: Colors.white)));
    }

    if (_currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      _initController(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content) {
       // External update
       int selectionBase = _controller!.selection.baseOffset;
       int selectionExtent = _controller!.selection.extentOffset;

       _controller!.text = activeFile.content;

       if (selectionBase <= activeFile.content.length && selectionExtent <= activeFile.content.length) {
          _controller!.selection = TextSelection(baseOffset: selectionBase, extentOffset: selectionExtent);
       }
    }

    final styles = {
      'root': const TextStyle(color: Color(0xfff8f8f2), backgroundColor: Colors.transparent),
      'comment': const TextStyle(color: Color(0xff75715e)),
      'quote': const TextStyle(color: Color(0xffe6db74)),
      'keyword': const TextStyle(color: Color(0xfff92672)),
      'selector-tag': const TextStyle(color: Color(0xfff92672)),
      'built_in': const TextStyle(color: Color(0xff66d9ef)),
      'number': const TextStyle(color: Color(0xffae81ff)),
      'string': const TextStyle(color: Color(0xffe6db74)),
      'meta': const TextStyle(color: Color(0xfff92672)),
      'literal': const TextStyle(color: Color(0xffae81ff)),
      'type': const TextStyle(color: Color(0xff66d9ef)),
      'params': const TextStyle(color: Color(0xfff8f8f2)),
      'title': const TextStyle(color: Color(0xffa6e22e)),
      'function': const TextStyle(color: Color(0xffa6e22e)),
    };

    return CodeTheme(
      data: CodeThemeData(styles: styles),
      child: CodeField(
        controller: _controller!,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        gutterStyle: const GutterStyle(
          textStyle: TextStyle(color: Colors.grey, height: 1.5),
          width: 50,
          margin: 0,
          background: Colors.transparent,
        ),
        background: Colors.transparent,
        expands: true,
        wrap: true,
      ),
    );
  }
}
