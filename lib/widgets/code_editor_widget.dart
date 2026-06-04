import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,
    );
    _controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerWithState();
  }

  void _syncControllerWithState() {
    final activeFile = ref.watch(fileProvider).activeFile;
    if (activeFile != null) {
      if (_currentFileId != activeFile.id) {
        _currentFileId = activeFile.id;
        _controller.text = activeFile.content;
      } else if (_controller.text != activeFile.content) {
         // Keep selection if text changed externally (e.g. from state)
         final selection = _controller.selection;
         _controller.text = activeFile.content;
         if (selection.baseOffset <= activeFile.content.length) {
            _controller.selection = selection;
         } else {
            _controller.selection = TextSelection.collapsed(offset: activeFile.content.length);
         }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-sync if state changed
    _syncControllerWithState();

    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              color: Colors.grey,
              height: 1.5,
              fontSize: 14,
            ),
            width: 48,
            margin: 8,
          ),
          background: Colors.transparent,
        ),
      ),
    );
  }
}
