import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:dart_style/dart_style.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  String? _currentFileId;

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
      setState(() {
        _currentFileId = activeFile.id;
        _codeController = CodeController(
          text: activeFile.content,
          language: dart,
        );
      });
    }
  }

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  void _onFileChanged(String newContent) {
    if (_currentFileId != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
    }
  }

  void _syncEditorWithState() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.id != _currentFileId) {
      _currentFileId = activeFile.id;
      final text = activeFile.content;
      _codeController?.text = text;
      // Cap selection to prevent RangeError
      if (_codeController != null) {
         if (_codeController!.selection.baseOffset > text.length) {
            _codeController!.selection = TextSelection.collapsed(offset: text.length);
         }
      }
    }
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        ref.read(fileProvider.notifier).createNewFile();
        Future.delayed(const Duration(milliseconds: 100), () {
           ref.read(fileProvider.notifier).updateActiveFileContent(content);
           _codeController?.text = content;
           Fluttertoast.showToast(msg: "Imported $name");
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
           directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final path = '${directory.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to $path");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Download failed: $e");
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Share Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code, color: Colors.white),
              title: const Text('Share raw text', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text('Share base64 encoded link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final bytes = utf8.encode(activeFile.content);
                final base64Str = base64.encode(bytes);
                final url = 'https://dartmini.com/share?code=\$base64Str';
                Share.share(url, subject: 'DartMini Code Link');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteFile(activeFile.id);
      Fluttertoast.showToast(msg: "File deleted");
    }
  }

  void _showExamplesGallery() {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello World!");\n}',
      'Async/Await': 'import "dart:async";\n\nFuture<void> main() async {\n  print("Waiting...");\n  await Future.delayed(Duration(seconds: 2));\n  print("Done!");\n}',
      'Classes & Lists': 'class Person {\n  String name;\n  Person(this.name);\n}\n\nvoid main() {\n  var people = [Person("Alice"), Person("Bob")];\n  for (var p in people) {\n    print("Hello, ${p.name}");\n  }\n}',
      'Input/Output': 'import "dart:io";\n\nvoid main() {\n  print("Enter value:");\n  var input = stdin.readLineSync();\n  print("You entered: $input");\n}'
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples Gallery', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...examples.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              subtitle: Text(e.value.replaceAll('\n', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                ref.read(fileProvider.notifier).createNewFile(name: "${e.key.replaceAll(' ', '_').toLowerCase()}.dart", content: e.value);
                Fluttertoast.showToast(msg: "Loaded ${e.key}");
              },
            )).toList(),
          ],
        );
      }
    );
  }

  void _runCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      // Dismiss keyboard
      FocusScope.of(context).unfocus();
      ref.read(executionProvider.notifier).executeCode(activeFile.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for file state changes to sync editor if another file is selected
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (next.activeFileId != _currentFileId) {
        _syncEditorWithState();
      }
    });

    final fileState = ref.watch(fileProvider);
    final isExecuting = ref.watch(executionProvider.select((s) => s.isExecuting));

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
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
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: isExecuting ? null : _runCode,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: isExecuting ? 0.5 : 1.0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (isExecuting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                    const SizedBox(width: 4),
                    const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
                        EditorToolbar(
              onNewFile: () => ref.read(fileProvider.notifier).createNewFile(),
              onGallery: _showExamplesGallery,
              onImport: _importFile,
              onCopy: () {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  Clipboard.setData(ClipboardData(text: activeFile.content));
                  Fluttertoast.showToast(msg: "Code copied to clipboard");
                }
              },
              onPaste: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                  final text = data.text!;
                  if (_codeController != null) {
                     final int cursorPosition = _codeController!.selection.baseOffset;
                     if(cursorPosition >= 0) {
                        final String currentText = _codeController!.text;
                        final String newText = currentText.substring(0, cursorPosition) + text + currentText.substring(cursorPosition);
                        _codeController!.text = newText;
                        _codeController!.selection = TextSelection.collapsed(offset: cursorPosition + text.length);
                        ref.read(fileProvider.notifier).updateActiveFileContent(newText);
                     } else {
                         _codeController!.text += text;
                         ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
                     }
                  }
                  Fluttertoast.showToast(msg: "Pasted from clipboard");
                }
              },
              onDownload: _downloadFile,
              onShare: _shareCode,
              onDelete: _confirmDelete,
              onSettings: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              onFormat: () {
                 final activeFile = ref.read(fileProvider).activeFile;
                 if (activeFile != null && _codeController != null) {
                     try {
                         final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                         final formatted = formatter.format(activeFile.content);
                         _codeController!.text = formatted;
                         ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                         Fluttertoast.showToast(msg: "Code formatted");
                     } catch (e) {
                         Fluttertoast.showToast(msg: "Format failed: Syntax error");
                     }
                 }
              },
              onClearOutput: () {
                 ref.read(executionProvider.notifier).clearOutput();
                 Fluttertoast.showToast(msg: "Output cleared");
              },
            ),

            // File Tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fileState.files.length,
                itemBuilder: (context, index) {
                  final file = fileState.files[index];
                  final isActive = file.id == fileState.activeFileId;
                  return InkWell(
                    onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white10 : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            file.name,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
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
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        CodeEditorWidget(
                          initialContent: fileState.activeFile?.content ?? '',
                          onChanged: _onFileChanged,
                          controller: _codeController!,
                        ),
                        const OutputSheet(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
