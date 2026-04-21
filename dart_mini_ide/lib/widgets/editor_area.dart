import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class EditorArea extends ConsumerStatefulWidget {
  const EditorArea({super.key});

  @override
  ConsumerState<EditorArea> createState() => _EditorAreaState();
}

class _EditorAreaState extends ConsumerState<EditorArea> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,

    );
    _controller.addListener(() {
      ref.read(fileProvider.notifier).updateActiveContent(_controller.text);
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
      if (next.activeFileId.isEmpty) return;
      if (previous?.activeFileId != next.activeFileId || next.files.any((f) => f.id == next.activeFileId && f.content != _controller.text)) {
        final activeContent = ref.read(fileProvider.notifier).activeFile?.content ?? '';
        if (_controller.text != activeContent) {
          final cursor = _controller.selection.baseOffset;
          _controller.text = activeContent;
          if (cursor <= activeContent.length && cursor >= 0) {
            _controller.selection = TextSelection.collapsed(offset: cursor);
          }
        }
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: draculaTheme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        gutterStyle: const GutterStyle(
          showLineNumbers: true,
          textStyle: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        expands: true,
        wrap: false,
      ),
    );
  }
}
