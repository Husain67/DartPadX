import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/app_toolbar.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/output_console.dart';
import '../theme/app_theme.dart';
import '../services/file_service.dart';
import 'package:dart_style/dart_style.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  String _currentActiveId = '';
  final FocusNode _editorFocusNode = FocusNode();
  final TextEditingController _stdinController = TextEditingController();

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
    if (_currentActiveId.isNotEmpty) {
      ref.read(fileProvider.notifier).updateFileContent(_currentActiveId, _codeController.text);
    }
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _editorFocusNode.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  void _handleNewFile() {
    ref.read(fileProvider.notifier).addFile();
  }

  Future<void> _handleImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
        Fluttertoast.showToast(msg: "File imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import file");
    }
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: _codeController.text));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final text = data.text!;
      final currentSelection = _codeController.selection;

      if (currentSelection.isValid) {
        final newText = _codeController.text.replaceRange(
          currentSelection.start,
          currentSelection.end,
          text,
        );
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(
          offset: currentSelection.start + text.length,
        );
      } else {
        _codeController.text += text;
      }
      Fluttertoast.showToast(msg: "Code pasted");
    }
  }

  Future<void> _handleDownload() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final path = await FileService.downloadFile(activeFile.name, activeFile.content);
      if (path != null) {
        Fluttertoast.showToast(msg: "Downloaded to \$path");
      } else {
        Fluttertoast.showToast(msg: "Download failed");
      }
    }
  }

  Future<void> _handleShare() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await FileService.shareCode(activeFile.name, activeFile.content);
    }
  }

  void _handleDelete() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete this file?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: "File deleted");
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }


  void _handleFormat() {
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(_codeController.text);
      _codeController.text = formatted;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format");
    }
  }

  void _handleSettings() {

    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active file changes to update code controller
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFileId != _currentActiveId) {
        // Force save current explicitly if needed before switching
        if (_currentActiveId.isNotEmpty && previous != null) {
          final _ = previous.files.firstWhere((f) => f.id == _currentActiveId, orElse: () => next.files.first);
           ref.read(fileProvider.notifier).updateFileContent(_currentActiveId, _codeController.text);
        }

        _currentActiveId = next.activeFileId;
        final newActiveFile = next.activeFile;
        if (newActiveFile != null) {
          if (_codeController.text != newActiveFile.content) {
             _codeController.text = newActiveFile.content;
          }
        }
      }
    });

    final execState = ref.watch(executionProvider);
    final isExecuting = execState.isExecuting;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
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
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Examples',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen())),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: isExecuting ? null : () {
                FocusScope.of(context).unfocus();
                ref.read(executionProvider.notifier).runCode();
              },
              icon: isExecuting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          AppToolbar(
            onNewFile: _handleNewFile,
            onImport: _handleImport,
            onCopy: _handleCopy,
            onPaste: _handlePaste,
            onDownload: _handleDownload,
            onShare: _handleShare,

            onDelete: _handleDelete,
            onFormat: _handleFormat,
            onSettings: _handleSettings,

          ),
          const EditorTabs(),
          Expanded(
            child: Stack(
              children: [
                CodeTheme(
                  data: CodeThemeData(styles: draculaTheme),
                  child: SingleChildScrollView(
                    child: CodeField(
                      controller: _codeController,
                      focusNode: _editorFocusNode,
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                      gutterStyle: const GutterStyle(
                        textStyle: TextStyle(color: Colors.grey, height: 1.5),
                        width: 40,
                      ),
                    ),
                  ),
                ),
                const OutputConsole(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.surfaceColor,
        child: TextField(
          controller: _stdinController,
          decoration: const InputDecoration(
            hintText: 'Standard Input (stdin)',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            ref.read(stdinProvider.notifier).state = val;
          },
        ),
      ),
    );
  }
}
