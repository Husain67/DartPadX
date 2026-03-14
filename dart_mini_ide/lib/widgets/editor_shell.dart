import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../utils/theme.dart';

class EditorShell extends ConsumerStatefulWidget {
  const EditorShell({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends ConsumerState<EditorShell> {
  late CodeController _controller;
  String _activeFileId = '';

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
    if (_activeFileId.isNotEmpty && ref.read(fileProvider).activeFileId == _activeFileId) {
      ref.read(fileProvider.notifier).updateFileContent(_activeFileId, _controller.text);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != _activeFileId) {
        _activeFileId = next.activeFileId;
        final file = ref.read(fileProvider.notifier).activeFile;
        if (file != null && _controller.text != file.content) {
          _controller.text = file.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    if (_activeFileId.isEmpty && activeFile != null) {
      _activeFileId = activeFile.id;
      _controller.text = activeFile.content;
    }

    return Column(
      children: [
        _buildTabs(fileState),
        Expanded(
          child: Container(
            color: const Color(0xFF2B2B2B),
            child: CodeTheme(
              data: CodeThemeData(styles: darculaTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: const GutterStyle(
                    textStyle: TextStyle(color: Colors.grey, height: 1.5),
                    showLineNumbers: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(FileState state) {
    return Container(
      height: 40,
      color: Colors.black,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundEnd : Colors.black,
                border: Border(
                  top: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  file.name,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
