import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:async';

import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../ui/theme/theme_constants.dart';
import '../../ui/widgets/toolbar.dart';
import '../../ui/widgets/output_sheet.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late CodeController _codeController;
  Timer? _saveTimer;
  String? _currentActiveId;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    if (_currentActiveId != null) {
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        ref.read(fileProvider.notifier).updateFileContent(
              _currentActiveId!,
              _codeController.text,
            );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _saveTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _forceSave() {
    if (_currentActiveId != null) {
      ref.read(fileProvider.notifier).updateFileContent(
            _currentActiveId!,
            _codeController.text,
          );
    }
  }

  void _runCode() {
    _forceSave();
    ref.read(executionProvider.notifier).executeCode(_codeController.text);
  }

  void _formatCode() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formattedCode = formatter.format(_codeController.text);
      _codeController.text = formattedCode;
      _forceSave();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    ref.listen(fileProvider, (previous, next) {
      final prevActive = previous?.activeFileId;
      final nextActive = next.activeFileId;
      if (prevActive != nextActive) {
        _forceSave();
        _currentActiveId = nextActive;
        final newFile = ref.read(fileProvider.notifier).activeFile;
        if (newFile != null && _codeController.text != newFile.content) {
          _codeController.text = newFile.content;
        }
      }
    });

    if (_currentActiveId == null && activeFile != null) {
      _currentActiveId = activeFile.id;
      _codeController.text = activeFile.content;
    }

    final executionState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: executionState.isExecuting ? null : _runCode,
              icon: executionState.isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(executionState.isExecuting ? 'Running' : 'Run'),
            ),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): _runCode,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR): _runCode,
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): _forceSave,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): _forceSave,
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF): _formatCode,
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF): _formatCode,
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 40,
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
                            decoration: BoxDecoration(
                              color: isActive ? ThemeConstants.backgroundEnd : Colors.black,
                              border: Border(
                                bottom: BorderSide(
                                  color: isActive ? ThemeConstants.primaryAccent : Colors.transparent,
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
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(fileProvider.notifier).deleteFile(file.id);
                                  },
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isActive ? Colors.white : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  CodeToolbar(codeController: _codeController, forceSave: _forceSave),
                  Expanded(
                    child: CodeTheme(
                      data: CodeThemeData(styles: draculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController,
                          gutterStyle: const GutterStyle(showLineNumbers: true),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (executionState.showOutput)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: OutputSheet(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
