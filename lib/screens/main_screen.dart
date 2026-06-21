import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar_button.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null) {
        _codeController.text = activeFile.content;
      }
    });
  }

  void _onCodeChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _runCode() {
    FocusScope.of(context).unfocus();
    final code = _codeController.text;
    final stdin = _stdinController.text;
    ref.read(executionProvider.notifier).executeCode(code, stdin);
    _showOutputSheet();
  }

  void _showOutputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final result = ref.watch(executionProvider);
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          const Text(
                            'Console Output',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              ref.read(executionProvider.notifier).clear();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (result.isLoading)
                        const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15)))
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (result.stdout.isNotEmpty)
                                  Text(result.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                                if (result.stderr.isNotEmpty)
                                  Text(result.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                                if (result.time.isNotEmpty || result.memory.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      'Time: ${result.time} • Memory: ${result.memory}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        final content = utf8.decode(file.bytes!);
        ref.read(fileProvider.notifier).addFile(file.name, content);
        _codeController.text = content;
        Fluttertoast.showToast(msg: "Imported ${file.name}");
      }
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    // Simplistic save feature using FilePicker or temporary sharing
    // For full storage we'd need path_provider.
    // Given the constraints and typical Android mobile storage scoped issues, we can share as file.
    Fluttertoast.showToast(msg: "Downloading not fully supported on generic platform, sharing instead.");
    _shareCode();
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final currentSelection = _codeController.selection;
      if (currentSelection.isValid) {
        final newText = _codeController.text.replaceRange(
          currentSelection.start,
          currentSelection.end,
          data.text!,
        );
        _codeController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: currentSelection.start + data.text!.length),
        );
      } else {
        _codeController.text += data.text!;
      }
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  void _shareCode() {
    Share.share(_codeController.text, subject: 'Dart Code from DartMini IDE');
  }

  void _formatCode() {
    // Very basic format representation
    Fluttertoast.showToast(msg: "Format code triggered");
    // Code formatting would require dart_style package, but it's not strictly required by constraints.
  }

  void _deleteFile() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");

              // Delay slightly so provider state updates before reading it
              Future.delayed(const Duration(milliseconds: 100), () {
                final newActive = ref.read(fileProvider).activeFile;
                if (newActive != null) {
                  _codeController.text = newActive.content;
                }
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExamples() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Examples Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Hello World'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('hello.dart', "void main() {\n  print('Hello World');\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('List Example'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('list.dart', "void main() {\n  var list = [1, 2, 3];\n  print(list);\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Class Example'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('class.dart', "class Person {\n  String name;\n  Person(this.name);\n}\nvoid main() {\n  var p = Person('DartMini');\n  print(p.name);\n}");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider.select((state) => state.activeFileId), (prev, next) {
      if (prev != next) {
        final active = ref.read(fileProvider).activeFile;
        if (active != null && _codeController.text != active.content) {
          _codeController.text = active.content;
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFACC15)),
              ),
              child: const Text('beta', style: TextStyle(fontSize: 10, color: Color(0xFFFACC15))),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              onPressed: execState.isLoading ? null : _runCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: execState.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Row(
                      children: [
                        Icon(Icons.play_arrow, size: 20),
                        SizedBox(width: 4),
                        Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
          ),
        ),
        child: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ToolbarButton(
                    label: 'New File',
                    icon: Icons.add,
                    onTap: () => ref.read(fileProvider.notifier).addFile('untitled.dart'),
                  ),
                  ToolbarButton(
                    label: 'Import .dart',
                    icon: Icons.file_download,
                    onTap: _importFile,
                  ),
                  ToolbarButton(
                    label: 'Copy code',
                    icon: Icons.copy,
                    onTap: _copyCode,
                  ),
                  ToolbarButton(
                    label: 'Paste',
                    icon: Icons.paste,
                    onTap: _pasteCode,
                  ),
                  ToolbarButton(
                    label: 'Download .dart',
                    icon: Icons.download,
                    onTap: _downloadFile,
                  ),
                  ToolbarButton(
                    label: 'Share',
                    icon: Icons.share,
                    onTap: _shareCode,
                  ),
                  ToolbarButton(
                    label: 'Format',
                    icon: Icons.format_align_left,
                    onTap: _formatCode,
                  ),
                  ToolbarButton(
                    label: 'Examples',
                    icon: Icons.book,
                    onTap: _showExamples,
                  ),
                  ToolbarButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    onTap: _deleteFile,
                  ),
                  ToolbarButton(
                    label: 'Settings',
                    icon: Icons.settings,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),

            // File Tabs
            Container(
              height: 40,
              color: Colors.black,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fileState.files.length,
                itemBuilder: (context, index) {
                  final file = fileState.files[index];
                  final isActive = file.id == fileState.activeFileId;
                  return GestureDetector(
                    onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1a1a1a) : Colors.black,
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
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
                          if (fileState.files.length > 1) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                              child: Icon(Icons.close, size: 14, color: isActive ? Colors.white : Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Editor
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(styles: darculaTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(
                      textStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Stdin input field at bottom
            Container(
              color: const Color(0xFF1a1a1a),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _stdinController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'stdin (Standard Input)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
