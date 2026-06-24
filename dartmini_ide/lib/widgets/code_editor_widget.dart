import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
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
      text: '',
      language: dart,
    );

    _controller.addListener(() {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile != null && _controller.text != activeFile.content) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllerFromState();
    });
  }

  void _updateControllerFromState() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && activeFile.id != _currentFileId) {
      _currentFileId = activeFile.id;
      if (_controller.text != activeFile.content) {
        _controller.text = activeFile.content;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        _updateControllerFromState();
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: darculaTheme['root']?.backgroundColor ?? const Color(0xFF2B2B2B),
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
