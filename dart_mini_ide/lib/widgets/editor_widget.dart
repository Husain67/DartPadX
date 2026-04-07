import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/dracula.dart';

import '../providers/file_provider.dart';
import '../theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  final Map<String, CodeController> _controllers = {};
  String? _activeId;

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String id, String text) {
    if (_activeId == id) {
      ref.read(fileProvider.notifier).updateActiveFileContent(text);
    }
  }

  CodeController _getController(String id, String initialContent) {
    if (!_controllers.containsKey(id)) {
      final ctrl = CodeController(
        text: initialContent,
        language: dart,
      );
      ctrl.addListener(() {
        _onTextChanged(id, ctrl.text);
      });
      _controllers[id] = ctrl;
    }
    return _controllers[id]!;
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != previous?.activeFileId) {
        setState(() {
          _activeId = next.activeFileId;
        });
      }

      final activeFile = next.activeFile;
      if (activeFile != null) {
        final ctrl = _getController(activeFile.id, activeFile.content);
        if (ctrl.text != activeFile.content) {
          final cursor = ctrl.selection;
          ctrl.text = activeFile.content;
          ctrl.selection = cursor;
        }
      }
    });

    if (_activeId == null && fileState.activeFileId != null) {
      _activeId = fileState.activeFileId;
    }

    if (fileState.files.isEmpty) {
      return const Center(child: Text('No files open.'));
    }

    return Column(
      children: [
        // Tabs
        Container(
          height: 40,
          color: Colors.black26,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == fileState.activeFileId;
              return GestureDetector(
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveFile(file.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.grey[800] : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.primaryYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.grey)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          ref.read(fileProvider.notifier).deleteFile(file.id);
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Editor
        Expanded(
          child: _activeId == null
              ? const SizedBox()
              : CodeTheme(
                  data: CodeThemeData(styles: draculaTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _getController(_activeId!, fileState.activeFile!.content),
                      gutterStyle: const GutterStyle(showLineNumbers: true),
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
