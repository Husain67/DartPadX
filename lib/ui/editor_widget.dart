import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

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
      text: '',
      language: dart,
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateContent(_currentFileId!, _controller.text);
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
    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    if (activeFile?.id != _currentFileId) {
      _currentFileId = activeFile?.id;
      if (activeFile != null && _controller.text != activeFile.content) {
        _controller.text = activeFile.content;
      }
    }

    if (fileState.files.isEmpty || activeFile == null) {
      return const Center(child: Text('No file opened'));
    }

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == activeFile.id;
              return GestureDetector(
                onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black26 : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(file.name),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: draculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                textStyle: const TextStyle(fontFamily: 'monospace'),
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
