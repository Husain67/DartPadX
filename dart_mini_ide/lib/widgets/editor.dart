import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String? _lastActiveFileId;

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
     // Use an asynchronous microtask to update riverpod state to avoid build-during-build errors
     Future.microtask(() {
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null && activeFile.content != _controller.text) {
           ref.read(fileProvider.notifier).updateContent(_controller.text);
        }
     });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      if (activeFile == null) {
        if (_controller.text != '') {
            _controller.text = '';
        }
        _lastActiveFileId = null;
        return;
      }

      // Update text if we switched files or an external update (like paste/format) happened
      if (_lastActiveFileId != activeFile.id || _controller.text != activeFile.content) {
         // Temporarily remove listener to avoid circular updates and cursor resets
         _controller.removeListener(_onTextChanged);

         // Only replace full text if it's completely different to preserve cursor as best as possible
         if (_controller.text != activeFile.content) {
            _controller.text = activeFile.content;
         }

         _lastActiveFileId = activeFile.id;
         _controller.addListener(_onTextChanged);
      }
    });

    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) {
       return const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)));
    }

    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(showLineNumbers: true, textStyle: TextStyle(color: Colors.grey)),
        ),
      ),
    );
  }
}
