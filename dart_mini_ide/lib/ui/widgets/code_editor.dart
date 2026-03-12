import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  Timer? _debounce;
  String? _activeFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,
    );
    _controller.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      final activeFile = next.activeFile;
      if (activeFile != null) {
        if (_activeFileId != activeFile.id) {
          // Changed file
          _activeFileId = activeFile.id;
          _controller.text = activeFile.content;
        } else if (_controller.text != activeFile.content) {
          // Content changed externally (e.g., import/paste)
          final selection = _controller.selection;
          _controller.text = activeFile.content;
          _controller.selection = selection.copyWith(
            baseOffset: selection.baseOffset.clamp(0, _controller.text.length),
            extentOffset: selection.extentOffset.clamp(0, _controller.text.length),
          );
        }
      } else {
        _controller.text = '';
        _activeFileId = null;
      }
    });

    final fileState = ref.watch(fileProvider);
    if (fileState.activeFileId == null && _controller.text.isEmpty) {
      final activeFile = fileState.activeFile;
      if (activeFile != null) {
         _controller.text = activeFile.content;
         _activeFileId = activeFile.id;
      }
    }

    return CodeTheme(
      data: CodeThemeData(styles: draculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(fontSize: 14, color: Colors.white54)),
          minLines: 20,
        ),
      ),
    );
  }
}
