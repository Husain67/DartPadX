import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'package:dart_style/dart_style.dart';

import '../../providers/file_provider.dart';
import '../../providers/compiler_provider.dart';
import '../../providers/execution_provider.dart';
import '../../services/execution_service.dart';
import '../../services/file_service.dart';
import '../widgets/toolbar_button.dart';
import '../theme.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  CodeController? _codeController;
  final TextEditingController _stdinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  void _initEditor() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(_onCodeChanged);
      setState(() {});
    }
  }

  void _onCodeChanged() {
    if (_codeController != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
    }
  }

  @override
  void dispose() {
    _codeController?.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _switchFile(String fileId) {
    ref.read(fileProvider.notifier).setActiveFile(fileId);
    final newActive = ref.read(fileProvider).files.firstWhere((f) => f.id == fileId);
    _codeController?.text = newActive.content;
  }

  void _runCode() async {
    final compilerState = ref.read(compilerProvider);
    final activePreset = compilerState.activePreset;
    if (activePreset == null) {
      Fluttertoast.showToast(msg: "No compiler preset selected");
      return;
    }

    final code = _codeController?.text ?? '';
    if (code.trim().isEmpty) return;

    ref.read(executionProvider.notifier).setRunning(true);
    _showOutputSheet();

    final result = await ExecutionService.executeCode(
      preset: activePreset,
      code: code,
      stdin: _stdinController.text,
    );

    ref.read(executionProvider.notifier).setOutput(
      stdout: result.stdout,
      stderr: result.stderr,
      executionTime: result.executionTime,
      memory: result.memory,
    );
  }

  void _showOutputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackgroundEnd,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _OutputSheet(),
    );
  }

  Future<void> _deleteCurrentFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteFile(activeFile.id);
      Fluttertoast.showToast(msg: "File deleted");

      // Update editor with next active file (or newly created default)
      Future.delayed(const Duration(milliseconds: 100), () {
        final newActive = ref.read(fileProvider).activeFile;
        if (newActive != null) {
          _codeController?.text = newActive.content;
        }
      });
    }
  }

  void _showExamplesGallery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hello World'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('hello.dart', "void main() {\n  print('Hello World');\n}");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('List & Map'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('list.dart', "void main() {\n  var list = [1, 2, 3];\n  print(list);\n}");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Class Example'),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('class.dart', "class Person {\n  String name;\n  Person(this.name);\n}\n\nvoid main() {\n  var p = Person('Dart');\n  print(p.name);\n}");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ToolbarButton(
              icon: Icons.play_arrow,
              label: 'Run',
              isPrimary: true,
              onTap: _runCode,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.darkBackgroundStart, AppTheme.darkBackgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                children: [
                  ToolbarButton(
                    icon: Icons.add,
                    label: 'New File',
                    onTap: () {
                      ref.read(fileProvider.notifier).createFile('untitled.dart');
                      Future.delayed(const Duration(milliseconds: 100), () {
                         _codeController?.text = '';
                      });
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.download_rounded,
                    label: 'Import .dart',
                    onTap: () async {
                      final content = await FileService.importFile();
                      if (content != null) {
                        ref.read(fileProvider.notifier).createFile('imported.dart', content);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _codeController?.text = content;
                        });
                        Fluttertoast.showToast(msg: "Imported successfully");
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.copy,
                    label: 'Copy code',
                    onTap: () async {
                      if (_codeController != null) {
                        await FileService.copyToClipboard(_codeController!.text);
                        Fluttertoast.showToast(msg: "Copied to clipboard");
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.paste,
                    label: 'Paste',
                    onTap: () async {
                      final text = await FileService.pasteFromClipboard();
                      if (text != null && _codeController != null) {
                        final start = _codeController!.selection.start;
                        final end = _codeController!.selection.end;

                        // Handle case where selection is not active (-1)
                        if (start == -1 || end == -1) {
                            _codeController!.text += text;
                        } else {
                            final currentText = _codeController!.text;
                            final newText = currentText.replaceRange(start, end, text);
                            _codeController!.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(offset: start + text.length),
                            );
                        }
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.file_download,
                    label: 'Download .dart',
                    onTap: () async {
                      final active = fileState.activeFile;
                      if (active != null) {
                        final success = await FileService.downloadFile(active.name, active.content);
                        Fluttertoast.showToast(msg: success ? "Saved to App storage" : "Failed to save");
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: () {
                      final active = fileState.activeFile;
                      if (active != null) {
                        FileService.shareFile(active.name, active.content);
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    onTap: _deleteCurrentFile,
                  ),
                  ToolbarButton(
                    icon: Icons.format_align_left,
                    label: 'Format Code',
                    onTap: () {
                      if (_codeController != null) {
                        try {
                          final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                          final formatted = formatter.format(_codeController!.text);
                          _codeController!.text = formatted;
                          Fluttertoast.showToast(msg: "Code formatted");
                        } catch (e) {
                          Fluttertoast.showToast(msg: "Syntax error: Cannot format");
                        }
                      }
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.library_books,
                    label: 'Examples',
                    onTap: () {
                      _showExamplesGallery();
                    },
                  ),
                  ToolbarButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            // Tabs
            if (fileState.files.isNotEmpty)
              Container(
                height: 40,
                color: AppTheme.pureBlack,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final file = fileState.files[index];
                    final isActive = file.id == fileState.activeFileId;
                    return GestureDetector(
                      onTap: () => _switchFile(file.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.darkBackgroundStart : AppTheme.pureBlack,
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? AppTheme.accentYellow : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                color: isActive ? AppTheme.accentYellow : Colors.grey,
                              ),
                            ),
                            if (fileState.files.length > 1) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // Can't delete directly from tab easily without confirmation, use current logic
                                  if (isActive) {
                                    _deleteCurrentFile();
                                  } else {
                                    ref.read(fileProvider.notifier).deleteFile(file.id);
                                  }
                                },
                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Editor
            Expanded(
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator())
                  : CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.grey, height: 1.3),
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
            ),

            // Stdin input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.pureBlack,
              child: TextField(
                controller: _stdinController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Standard Input (stdin)',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.keyboard, color: Colors.grey, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutputSheet extends ConsumerWidget {
  const _OutputSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Console Output', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                  )
                ],
              ),
              const Divider(color: Colors.grey),
              if (execState.isRunning)
                const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow))
              else
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (execState.stdout.isNotEmpty)
                        Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (execState.stderr.isNotEmpty)
                        Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                      if (execState.executionTime.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Time: ${execState.executionTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                      if (execState.memory.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
