import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class EditorView extends ConsumerStatefulWidget {
  const EditorView({super.key});

  @override
  ConsumerState<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<EditorView> {
  late CodeController _controller;
  String? _activeFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );

    _controller.addListener(() {
      final text = _controller.text;
      ref.read(fileProvider.notifier).updateContent(text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _activeFileId) {
        _activeFileId = next.activeFileId;
        if (next.activeFile != null) {
          _controller.text = next.activeFile!.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    if (fileState.activeFile == null) {
      return const Center(child: Text('No file selected', style: TextStyle(color: Colors.white54)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(color: Colors.white54)),
      ),
    );
  }
}
