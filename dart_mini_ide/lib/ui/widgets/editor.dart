import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import '../../providers/file_provider.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  late CodeController _controller;
  final Debouncer _debouncer = Debouncer(milliseconds: 2000);
  String _currentActiveFileId = '';

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );

    _controller.addListener(() {
      _debouncer.run(() {
        if (_currentActiveFileId.isNotEmpty) {
          ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _forceSave() {
    if (_currentActiveFileId.isNotEmpty) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveFileId) {
        if (previous != null && previous.activeFileId == _currentActiveFileId) {
          _forceSave();
        }

        _currentActiveFileId = next.activeFileId;
        final activeFile = ref.read(fileProvider.notifier).activeFile;
        if (activeFile != null) {
          _controller.text = activeFile.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final activeFileId = fileState.activeFileId;

    if (fileState.files.isEmpty) {
      return const Center(child: Text('No files open', style: TextStyle(color: Colors.white)));
    }

    return Column(
      children: [
        Container(
          height: 40,
          color: AppConstants.bgColorEnd,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fileState.files.length,
            itemBuilder: (context, index) {
              final file = fileState.files[index];
              final isActive = file.id == activeFileId;

              return GestureDetector(
                onTap: () {
                  _forceSave();
                  ref.read(fileProvider.notifier).setActiveFile(file.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive ? AppConstants.bgColorStart : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppConstants.accentColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? AppConstants.accentColor : Colors.white.withValues(alpha: 255 * 0.7),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _forceSave();
                          ref.read(fileProvider.notifier).deleteFile(file.id);
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isActive ? AppConstants.accentColor : Colors.white.withValues(alpha: 255 * 0.5),
                        ),
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
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
