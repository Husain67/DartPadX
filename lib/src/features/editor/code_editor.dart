import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'dart:async';
import '../../providers/files_provider.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  late CodeController _controller;
  Timer? _debounce;
  String _currentActiveId = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
    _controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentActiveId.isNotEmpty) {
        ref.read(filesProvider.notifier).updateActiveFileContent(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FilesState>(filesProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        // flush current
        if (_currentActiveId.isNotEmpty && previous != null) {
             final prevFile = previous.files.firstWhere((f) => f.id == _currentActiveId, orElse: () => previous.files.first);
             if(prevFile.id == _currentActiveId) {
                ref.read(filesProvider.notifier).updateActiveFileContent(_controller.text);
             }
        }
        _currentActiveId = next.activeFileId;
        if (_currentActiveId.isNotEmpty) {
          final activeFile = next.files.firstWhere((f) => f.id == _currentActiveId);
          if (_controller.text != activeFile.content) {
            _controller.text = activeFile.content;
          }
        } else {
           _controller.text = '';
        }
      } else {
          // content might have changed externally (format, paste)
          if (_currentActiveId.isNotEmpty) {
            final activeFile = next.files.firstWhere((f) => f.id == _currentActiveId);
            if (_controller.text != activeFile.content) {
              final selection = _controller.selection;
              _controller.text = activeFile.content;
              if (selection.baseOffset <= activeFile.content.length && selection.extentOffset <= activeFile.content.length) {
                 _controller.selection = selection;
              }
            }
          }
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          gutterStyle: const GutterStyle(showLineNumbers: true),
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
      ),
    );
  }
}
