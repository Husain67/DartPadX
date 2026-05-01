import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  Timer? _debounce;
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
    if (!mounted) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null && activeFile.content != _controller.text) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
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
    ref.listen(fileProvider, (previous, next) {
      final activeFile = next.activeFile;
      if (activeFile != null && activeFile.id != _currentFileId) {
        // flush old file state if there was a previous one
        final prevActiveFile = previous?.activeFile;
        if (prevActiveFile != null && prevActiveFile.id == _currentFileId && prevActiveFile.content != _controller.text) {
           ref.read(fileProvider.notifier).forceUpdateFile(prevActiveFile.copyWith(content: _controller.text));
        }

        _currentFileId = activeFile.id;
        if (_controller.text != activeFile.content) {
          _controller.text = activeFile.content;
        }
      } else if (activeFile != null && _controller.text != activeFile.content) {
        // To handle external updates like Paste/Import
        final currentSelection = _controller.selection;
        _controller.text = activeFile.content;
        // Best effort to maintain selection, but might be out of bounds if content shrank
        if (currentSelection.start <= activeFile.content.length && currentSelection.end <= activeFile.content.length) {
            _controller.selection = currentSelection;
        }
      }
    });

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        background: Colors.transparent,
        expands: true,
      ),
    );
  }
}
