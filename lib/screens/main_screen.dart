import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar_buttons.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';
import 'examples_gallery.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fileState = ref.read(fileProvider);
      if (fileState.activeFile != null) {
        _codeController.text = fileState.activeFile!.content;
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
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _runCode() {
    final fileState = ref.read(fileProvider);
    final compilerState = ref.read(compilerProvider);

    if (fileState.activeFile == null) return;

    FocusScope.of(context).unfocus(); // Hide keyboard

    ref.read(executionProvider.notifier).executeCode(
      _codeController.text,
      _stdinController.text,
      compilerState.activePreset,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }

  void _newFile() {
    showDialog(
      context: context,
      builder: (context) {
        String fileName = '';
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Filename (e.g. test.dart)'),
            onChanged: (val) => fileName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (fileName.isNotEmpty) {
                  if (!fileName.endsWith('.dart')) fileName += '.dart';
                  ref.read(fileProvider.notifier).addFile(fileName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
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
        ref.read(fileProvider.notifier).addFile(name, content: content);
        Fluttertoast.showToast(msg: "Imported \$name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  Future<void> _pasteCode() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final currentPos = _codeController.selection.baseOffset;
      final text = _codeController.text;
      if (currentPos >= 0 && currentPos <= text.length) {
        final newText = text.substring(0, currentPos) + data.text! + text.substring(currentPos);
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
      } else {
        _codeController.text += data.text!;
      }
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = '\${dir.path}/\${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to \$path");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving file");
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    Share.share(activeFile.content, subject: activeFile.name);
  }

  void _formatCode() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(_codeController.text);
      _codeController.text = formatted;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error, cannot format");
    }
  }

  void _deleteCurrentFile() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    // Sync controller if active file changed externally (like tab switch)
    if (fileState.activeFile != null &&
        _codeController.text != fileState.activeFile!.content &&
        !_editorFocusNode.hasFocus) {
      _codeController.text = fileState.activeFile!.content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
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
          IconButton(
            icon: const Icon(Icons.explore, color: Colors.white),
            tooltip: 'Examples Gallery',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesGallery()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : _runCode,
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // File Tabs
          Container(
            height: 40,
            color: const Color(0xFF1A1A1A),
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
                      color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
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
                        if (fileState.files.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                            child: const Icon(Icons.close, size: 16, color: Colors.white54),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Toolbar
          Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                ToolbarButton(label: 'New', icon: Icons.insert_drive_file, onPressed: _newFile),
                ToolbarButton(label: 'Import', icon: Icons.file_download, onPressed: _importFile),
                ToolbarButton(label: 'Copy', icon: Icons.copy, onPressed: _copyCode),
                ToolbarButton(label: 'Paste', icon: Icons.paste, onPressed: _pasteCode),
                ToolbarButton(label: 'Format', icon: Icons.format_align_left, onPressed: _formatCode),
                ToolbarButton(label: 'Download', icon: Icons.save_alt, onPressed: _downloadFile),
                ToolbarButton(label: 'Share', icon: Icons.share, onPressed: _shareCode),
                ToolbarButton(label: 'Delete', icon: Icons.delete_outline, onPressed: _deleteCurrentFile),
                ToolbarButton(
                  label: 'Settings',
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }
                ),
              ],
            ),
          ),

          // Code Editor
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: monokaiSublimeTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _codeController,
                  focusNode: _editorFocusNode,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: GutterStyle(
                    textStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                    showLineNumbers: true,
                    margin: 8.0,
                  ),
                ),
              ),
            ),
          ),

          // Stdin Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1A1A1A),
            child: TextField(
              controller: _stdinController,
              decoration: const InputDecoration(
                hintText: 'Standard Input (stdin)...',
                border: InputBorder.none,
                icon: Icon(Icons.input, color: Colors.white54),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
