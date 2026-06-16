import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final activeFileId = ref.read(fileProvider).activeFileId;
    if (activeFileId != null && activeFileId == _currentFileId) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first,
    );

    if (_currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = activeFile.content;
      });
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        gutterStyle: const GutterStyle(
          textStyle: TextStyle(color: Colors.white54, height: 1.5),
          width: 40,
        ),
      ),
    );
  }
}
