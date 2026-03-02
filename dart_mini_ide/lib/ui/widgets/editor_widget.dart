import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({Key? key}) : super(key: key);

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
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content != _controller.text) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateController();
  }

  void _updateController() {
    final activeFile = ref.watch(fileProvider).activeFile;
    if (activeFile != null && _currentFileId != activeFile.id) {
      _currentFileId = activeFile.id;
      final currentText = _controller.text;
      if (currentText != activeFile.content) {
        // Prevent recursive loop by temporarily removing listener
        _controller.removeListener(_onTextChanged);
        _controller.text = activeFile.content;
        _controller.addListener(_onTextChanged);
      }
    } else if (activeFile == null) {
      _currentFileId = null;
      _controller.text = '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFile?.id != _currentFileId) {
        _updateController();
      } else if (next.activeFile?.content != _controller.text) {
         // This handles content changed from outside (e.g. paste from toolbar)
         _controller.removeListener(_onTextChanged);
         final position = _controller.selection;
         _controller.text = next.activeFile?.content ?? '';
         try {
           _controller.selection = position;
         } catch(e){
            // Selection might be out of bounds if content shrank heavily
         }
         _controller.addListener(_onTextChanged);
      }
    });

    final isFileActive = ref.watch(fileProvider).activeFile != null;

    if (!isFileActive) {
      return const Center(
        child: Text(
          'Select or create a file to start coding.',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return CodeTheme(
      data: CodeThemeData(styles: draculaTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _controller,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
             showLineNumbers: true,
             width: 48,
             margin: 8,
             textStyle: TextStyle(color: Colors.white30, height: 1.5),
          ),
          minLines: 20,
        ),
      ),
    );
  }
}
