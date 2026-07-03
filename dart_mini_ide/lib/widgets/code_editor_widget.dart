import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _currentFileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateController();
  }

  void _updateController() {
    final activeFile = ref.watch(fileProvider).activeFile;

    if (activeFile?.id != _currentFileId) {
      _currentFileId = activeFile?.id;
      final oldController = _controller;

      if (activeFile != null) {
        _controller = CodeController(
          text: activeFile.content,
          language: dart,
        );
        _controller!.addListener(() {
          ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
        });
      } else {
        _controller = null;
      }

      oldController?.dispose();
    } else if (activeFile != null && _controller != null && _controller!.text != activeFile.content) {
        final currentSelection = _controller!.selection;
        _controller!.text = activeFile.content;

        if (currentSelection.baseOffset <= _controller!.text.length) {
            _controller!.selection = currentSelection;
        } else {
            _controller!.selection = TextSelection.collapsed(offset: _controller!.text.length);
        }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateController();

    if (_controller == null) {
      return const Center(child: Text('No file selected', style: TextStyle(color: Colors.white)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.grey),
            width: 40,
            margin: 10,
          ),
        ),
      ),
    );
  }
}
