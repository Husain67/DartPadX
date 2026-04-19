import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../theme.dart';

class EditorArea extends ConsumerStatefulWidget {
  const EditorArea({super.key});

  @override
  ConsumerState<EditorArea> createState() => _EditorAreaState();
}

class _EditorAreaState extends ConsumerState<EditorArea> {
  late CodeController _codeController;
  String? _currentActiveId;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentActiveId != null) {
      ref.read(fileProvider.notifier).updateActiveContent(_codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId ||
         (next.activeFile != null && next.activeFile!.content != _codeController.text && _currentActiveId == next.activeFileId)) {

        // Force save current before switching
        if (_currentActiveId != null && previous?.activeFile != null && previous?.activeFileId != next.activeFileId) {
           ref.read(fileProvider.notifier).forceSave(_currentActiveId!, _codeController.text);
        }

        _currentActiveId = next.activeFileId;
        if (next.activeFile != null) {
          final newContent = next.activeFile!.content;
          if (_codeController.text != newContent) {
            _codeController.text = newContent;
          }
        } else {
          _codeController.text = '';
        }
      }
    });

    if (fileState.files.isEmpty) {
      return const Center(child: Text("No files open", style: TextStyle(color: Colors.white54)));
    }

    return Column(
      children: [
        _buildTabBar(fileState),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.white54, height: 1.5),
                ),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
                minLines: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(FileState fileState) {
    return Container(
      height: 40,
      color: Colors.black45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;

          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.darkBackgroundBottom : Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: isActive ? AppTheme.accentYellow : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    file.title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (isActive) {
                        ref.read(fileProvider.notifier).deleteActiveFile();
                      }
                    },
                    child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.transparent),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
