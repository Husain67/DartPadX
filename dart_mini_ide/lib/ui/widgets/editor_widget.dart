import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _controller!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentFileId != null && _controller != null) {
       ref.read(fileListProvider.notifier).updateFileContent(_currentFileId!, _controller!.text);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = ref.watch(activeFileProvider);

    if (activeFile == null) {
      return const Center(child: Text("No file selected"));
    }

    if (_currentFileId != activeFile.id) {
       _currentFileId = activeFile.id;
       _initController(activeFile.content);
    } else if (_controller != null && _controller!.text != activeFile.content) {
       // External update logic
       // Only update if difference is significant or forced
       // Simple check to avoid cursor jump loop:
       // If the provider content is different from controller, and controller hasn't just typed (which we can't easily check),
       // we assume it's an external update (e.g. paste from toolbar).
       // However, since typing updates provider, provider notifies back.
       // We need to break the loop.
       // The simplest way is to check if the new content is what we just sent.
       // Since we don't have that info easily, we can check if the text is effectively the same.
       // If strings are equal, we do nothing.
       // If strings are different, it's either an external change OR a very fast race condition.
       // Given Riverpod is synchronous for this, it should be fine.
       // But to be safe, we can just update the text and lose cursor position if it's an external update.
       // Or we try to be smart.

       // For now, let's just update. The user explicitly pasted via toolbar, so losing cursor position (it goes to end usually) is acceptable-ish.
       // But better to try to keep it.

       // final val = _controller!.value;
       _controller!.text = activeFile.content;
       // _controller!.value = val.copyWith(text: activeFile.content); // this might keep selection if valid
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CodeTheme(
      data: CodeThemeData(styles: const {
        'root': TextStyle(
          backgroundColor: Colors.transparent,
          color: Colors.white,
        ),
        'comment': TextStyle(color: Color(0xFF6A9955)),
        'quote': TextStyle(color: Color(0xFFCE9178)),
        'keyword': TextStyle(color: Color(0xFF569CD6)),
        'number': TextStyle(color: Color(0xFFB5CEA8)),
        'string': TextStyle(color: Color(0xFFCE9178)),
        'built_in': TextStyle(color: Color(0xFF4EC9B0)),
        'type': TextStyle(color: Color(0xFF4EC9B0)),
        'title': TextStyle(color: Color(0xFFDCDCAA)),
        'function': TextStyle(color: Color(0xFFDCDCAA)),
        'class': TextStyle(color: Color(0xFF4EC9B0)),
      }),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller!,
          textStyle: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(color: Colors.grey, height: 1.5),
            showLineNumbers: true,
            width: 50,
            margin: 0,
            background: Colors.transparent,
          ),
          background: Colors.transparent,
          wrap: true,
        ),
      ),
    );
  }
}
