import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

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
      language: dart,
                );
    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProvider();
    });
  }

  void _onTextChanged() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content != _controller.text) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  void _syncWithProvider() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.id != _currentFileId) {
      _currentFileId = activeFile.id;
      if (_controller.text != activeFile.content) {
        _controller.text = activeFile.content;
      }
    } else if (activeFile != null && _controller.text != activeFile.content && !FocusScope.of(context).hasFocus) {
       _controller.text = activeFile.content;
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
    ref.listen(fileProvider.select((state) => state.activeFileId), (prev, next) {
      _syncWithProvider();
    });

    // Also listen to content changes explicitly triggered from outside (e.g. format, paste)
    ref.listen(fileProvider.select((state) => state.activeFile?.content), (prev, next) {
        if (next != null && next != _controller.text) {
          final selection = _controller.selection;
          _controller.text = next;
          if (selection.baseOffset <= next.length) {
            _controller.selection = selection;
          } else {
             _controller.selection = TextSelection.collapsed(offset: next.length);
          }
        }
    });

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: AppTheme.backgroundStart,
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(color: Colors.white54, fontSize: 12),
              width: 40,
              showLineNumbers: true,
            ),
          ),
        ),
      ),
    );
  }
}
