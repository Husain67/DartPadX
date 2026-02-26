import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class CodeEditor extends ConsumerWidget {
  const CodeEditor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final currentFile = fileState.currentFile;

    if (currentFile == null) {
      return const Center(
        child: Text(
          'No file selected',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return _EditorInternal(
      key: ValueKey(currentFile.name), // Re-init when file switches
      initialContent: currentFile.content,
      onChanged: (val) {
        ref.read(fileProvider.notifier).updateContent(val);
      },
    );
  }
}

class _EditorInternal extends StatefulWidget {
  final String initialContent;
  final ValueChanged<String> onChanged;

  const _EditorInternal({
    Key? key,
    required this.initialContent,
    required this.onChanged,
  }) : super(key: key);

  @override
  __EditorInternalState createState() => __EditorInternalState();
}

class __EditorInternalState extends State<_EditorInternal> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: widget.initialContent,
      language: dart,
    );
  }

  @override
  void didUpdateWidget(_EditorInternal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != _controller.text) {
      // Avoid resetting cursor if content matches (user typing)
      // Only update if external change (e.g. Paste, Import)
      // Note: This simple check assumes synchronous updates are fast enough.
      // If user types 'a', controller has 'a', widget.initialContent has 'a'. No reset.
      // If Import happens, widget.initialContent has 'new', controller has 'old'. Reset.
      _controller.text = widget.initialContent;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: CodeField(
        controller: _controller,
        onChanged: widget.onChanged,
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        expands: true,
        background: const Color(0xFF1e1e1e),
        lineNumberStyle: const LineNumberStyle(
           width: 48,
           margin: 4,
           textStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
