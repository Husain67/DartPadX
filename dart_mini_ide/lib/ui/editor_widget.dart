import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../utils/theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _codeController;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _codeController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initOrUpdateController(String text) {
    if (_codeController == null) {
      _codeController = CodeController(
        text: text,
        language: dart,
      );
      _codeController!.addListener(_onTextChanged);
    } else if (_codeController!.text != text) {
      // Temporarily remove listener to avoid triggering update back to state
      _codeController!.removeListener(_onTextChanged);
      final selection = _codeController!.selection;
      _codeController!.text = text;

      // Attempt to restore selection if it's within bounds
      if (selection.baseOffset <= text.length && selection.extentOffset <= text.length) {
         _codeController!.selection = selection;
      }

      _codeController!.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (_codeController != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    ref.listen(fileProvider, (previous, next) {
      if (next.activeFile != null) {
        if (previous?.activeFileId != next.activeFileId) {
           _initOrUpdateController(next.activeFile!.content);
        }
      }
    });

    if (activeFile == null) {
      return const Center(
        child: Text(
          'No files open.\nClick + New or Import to start.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    _initOrUpdateController(activeFile.content);

    return Column(
      children: [
        // Tabs
        SizedBox(
          height: 40,
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
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppTheme.accentYellow : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, size: 14, color: isActive ? AppTheme.accentYellow : Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                        child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.white54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Editor
        Expanded(
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
                 // Save / format shortcut
                 final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                 try {
                   final formatted = formatter.format(_codeController!.text);
                   _codeController!.text = formatted;
                 } catch (_) {}
              },
              const SingleActivator(LogicalKeyboardKey.keyR, control: true): () {
                 // Run shortcut
                 if (!ref.read(executionProvider).isRunning) {
                   ref.read(executionProvider.notifier).executeCode(_codeController!.text);
                 }
              }
            },
            child: CodeTheme(
              data: CodeThemeData(styles: atomOneDarkTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _codeController!,
                  focusNode: _focusNode,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: const GutterStyle(
                    showLineNumbers: true,
                    textStyle: TextStyle(color: Colors.white30, fontSize: 14, fontFamily: 'monospace'),
                  ),
                  background: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
