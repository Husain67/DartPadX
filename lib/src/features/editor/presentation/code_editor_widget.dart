import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:dartmini_ide/src/features/editor/providers/file_provider.dart';

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  late CodeController _controller;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      language: dart,
      text: '',
    );

    _controller.addListener(_onTextChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithState();
    });
  }

  void _onTextChanged() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.content != _controller.text) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  void _syncWithState() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile?.id != _currentFileId) {
      _currentFileId = activeFile?.id;
      final newText = activeFile?.content ?? '';
      if (_controller.text != newText) {
        // preserve cursor selection if possible, cap to max length
        final currentSelection = _controller.selection;
        _controller.text = newText;
        if (currentSelection.baseOffset <= newText.length) {
             _controller.selection = currentSelection;
        } else {
             _controller.selection = TextSelection.collapsed(offset: newText.length);
        }
      }
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
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
         _syncWithState();
      } else if (previous?.activeFile?.content != next.activeFile?.content && _controller.text != next.activeFile?.content) {
         _syncWithState();
      }
    });

    final files = ref.watch(fileProvider.select((state) => state.files));
    final activeFileId = ref.watch(fileProvider.select((state) => state.activeFileId));

    return Column(
      children: [
        _buildTabs(files, activeFileId),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: darculaTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                minLines: 20,
                padding: const EdgeInsets.only(bottom: 150),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(List<dynamic> files, String? activeId) {
    return Container(
      height: 40,
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? Colors.white10 : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                       ref.read(fileProvider.notifier).setActiveFile(file.id);
                       ref.read(fileProvider.notifier).deleteActiveFile();
                    },
                    child: const Icon(Icons.close, size: 14, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
