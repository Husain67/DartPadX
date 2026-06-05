import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/providers.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  String? _currentFileId;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController();
    });
  }

  void _initController() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      _currentFileId = activeFile.id;
      _controller = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _controller!.addListener(_onTextChanged);
      setState(() {});
    }
  }

  void _onTextChanged() {
    if (_controller == null || _currentFileId == null) return;

    // Auto-save debounce
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller!.text);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller?.removeListener(_onTextChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider.select((state) => state.activeFileId), (previous, next) {
      if (next != _currentFileId && next != null) {
        final newFile = ref.read(fileProvider.notifier).activeFile;
        if (newFile != null) {
          _currentFileId = next;
          _controller?.removeListener(_onTextChanged);

          final textLength = newFile.content.length;
          _controller?.text = newFile.content;

          // Reset selection safely
          _controller?.selection = TextSelection.collapsed(offset: textLength);

          _controller?.addListener(_onTextChanged);
        }
      }
    });

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.white54, height: 1.5),
            width: 40,
            margin: 8,
          ),
          background: Colors.transparent,
          expands: false,
          wrap: false,
        ),
      ),
    );
  }
}
