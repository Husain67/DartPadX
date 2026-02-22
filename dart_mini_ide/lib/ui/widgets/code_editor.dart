import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => CodeEditorState();
}

class CodeEditorState extends ConsumerState<CodeEditor> {
  CodeController? _controller;
  String? _currentFileId;

  String get currentCode => _controller?.text ?? '';

  void insertText(String text) {
    if (_controller != null) {
      final selection = _controller!.selection;
      if (selection.isValid) {
        final newText = _controller!.text.replaceRange(
          selection.start,
          selection.end,
          text,
        );
        _controller!.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.start + text.length),
        );
      } else {
        _controller!.text += text;
      }
    }
  }

  void replaceCode(String text) {
    if (_controller != null) {
      _controller!.text = text;
    }
  }

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
      if (_currentFileId != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text('No file selected', style: TextStyle(color: Colors.white)));
    }

    if (_currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      _initController(activeFile.content);
    }

    if (_controller == null) {
         _currentFileId = activeFile.id;
        _initController(activeFile.content);
    }

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: Container(
        color: const Color(0xFF050505),
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.4,
          ),
          gutterStyle: const GutterStyle(
             textStyle: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.4,
             ),
             width: 48,
             margin: 0,
             background: Color(0xFF151515),
          ),
          expands: true,
          wrap: false,
        ),
      ),
    );
  }
}
