import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/providers.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  bool _isUpdatingFromProvider = false;
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _controller!.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_isUpdatingFromProvider) return;
    if (_controller != null) {
       ref.read(filesProvider.notifier).updateActiveFileContent(_controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(filesProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(child: Text("No file open"));
    }

    if (_controller == null || _lastActiveIndex != fileState.activeIndex) {
      _lastActiveIndex = fileState.activeIndex;
      _initController(activeFile.content);
    } else if (_controller!.text != activeFile.content) {
      // Content updated from outside (e.g., formatting)
      _isUpdatingFromProvider = true;
      _controller!.text = activeFile.content;
      _isUpdatingFromProvider = false;
    }

    return CodeTheme(
      data: CodeThemeData(styles: darculaTheme),
      child: Container(
        color: const Color(0xFF2B2B2B), // darcula background
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller!,
            gutterStyle: const GutterStyle(
              textStyle: TextStyle(
                height: 1.5,
                color: Colors.grey,
              ),
            ),
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
      ),
    );
  }
}
