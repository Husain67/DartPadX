import 'dart:convert';
import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  final TextEditingController _stdinController = TextEditingController();
  String _currentFileId = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initEditor();
    });
  }

  void _initEditor() {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first
    );

    _currentFileId = activeFile.id;

    _codeController = CodeController(
      text: activeFile.content,
      language: dart,
    );

    _codeController!.addListener(() {
      if (_currentFileId.isNotEmpty && !_isSyncing) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController!.text);
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _codeController?.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId && _codeController != null) {
        _isSyncing = true;
        final activeFile = next.files.firstWhere(
          (f) => f.id == next.activeFileId,
          orElse: () => next.files.first
        );
        _currentFileId = activeFile.id;
        final currentPos = _codeController!.selection.baseOffset;
        final newText = activeFile.content;

        _codeController!.text = newText;
        if (currentPos >= 0 && currentPos <= newText.length) {
          _codeController!.selection = TextSelection.collapsed(offset: currentPos);
        } else {
          _codeController!.selection = TextSelection.collapsed(offset: newText.length);
        }
        _isSyncing = false;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: _buildAppBar(execState),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(context),
                _buildFileTabs(fileState),
                Expanded(
                  child: _codeController == null
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                      : SingleChildScrollView(
                          child: CodeTheme(
                            data: CodeThemeData(styles: darculaTheme),
                            child: CodeField(
                              controller: _codeController!,
                              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                              gutterStyle: const GutterStyle(
                                showLineNumbers: true,
                                textStyle: TextStyle(color: Colors.white54),
                                width: 40,
                              ),
                              minLines: 20,
                              wrap: false,
                            ),
                          ),
                        ),
                ),
                _buildStdinInput(),
                const SizedBox(height: 60), // padding for output sheet handle
              ],
            ),
            const OutputSheet(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ExecutionState execState) {
    return AppBar(
      title: Row(
        children: [
          const Text('DartMini', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'beta',
              style: TextStyle(color: AppTheme.pureBlack, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: execState.isExecuting ? null : () {
              ref.read(executionProvider.notifier).executeCode(_stdinController.text);
              FocusScope.of(context).unfocus();
            },
            icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppTheme.pureBlack, strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('Run'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => ref.read(fileProvider.notifier).createNewFile(),
          ),
          ToolbarButton(
            icon: Icons.download,
            label: 'Import .dart',
            onTap: _importFile,
          ),
          ToolbarButton(
            icon: Icons.save_alt,
            label: 'Download .dart',
            onTap: _downloadFile,
          ),
          ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: _formatCode,
          ),
          ToolbarButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: _showExamplesGallery,
          ),
          ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: _copyCode,
          ),
          ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: _pasteCode,
          ),
          ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _shareCode,
          ),
          ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: _deleteFile,
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
    );
  }

  Widget _buildFileTabs(FileState fileState) {
    return Container(
      height: 40,
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryYellow : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryYellow : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (fileState.files.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      color: AppTheme.textSecondary,
                      onPressed: () {
                        // Switch active to this, then delete
                        ref.read(fileProvider.notifier).setActiveFile(file.id);
                        ref.read(fileProvider.notifier).deleteActiveFile();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      splashRadius: 12,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStdinInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _stdinController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Standard Input (stdin)',
          hintText: 'Enter input for stdin.readLineSync()...',
        ),
      ),
    );
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null) {
        final path = result.files.single.path!;
        final file = io.File(path);
        final content = await file.readAsString();
        ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
        Fluttertoast.showToast(msg: "Imported \\${result.files.single.name}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: \\$e");
    }
  }

  Future<void> _downloadFile() async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.files.firstWhere(
      (f) => f.id == fileState.activeFileId,
      orElse: () => fileState.files.first
    );
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '\\${dir.path}/\\${activeFile.name}';
      final file = io.File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to \\$path");
    } catch (e) {
      Fluttertoast.showToast(msg: "Save failed: \\$e");
    }
  }

  void _formatCode() {
    if (_codeController != null && _codeController!.text.isNotEmpty) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(_codeController!.text);

        final currentPos = _codeController!.selection.baseOffset;
        _codeController!.text = formatted;

        if (currentPos >= 0 && currentPos <= formatted.length) {
          _codeController!.selection = TextSelection.collapsed(offset: currentPos);
        } else {
          _codeController!.selection = TextSelection.collapsed(offset: formatted.length);
        }
        Fluttertoast.showToast(msg: "Code formatted successfully");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed (syntax error)");
      }
    }
  }

  void _showExamplesGallery() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Examples Gallery", style: TextStyle(color: AppTheme.primaryYellow, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ListTile(
            title: const Text("Hello World", style: TextStyle(color: Colors.white)),
            onTap: () => _loadExample("Hello World", "void main() {\n  print('Hello, World!');\n}"),
          ),
          ListTile(
            title: const Text("Input/Output", style: TextStyle(color: Colors.white)),
            onTap: () => _loadExample("Input/Output", "import 'dart:io';\nvoid main() {\n  print('Enter name:');\n  String? name = stdin.readLineSync();\n  print('Hello \$name');\n}"),
          ),
          ListTile(
            title: const Text("List Processing", style: TextStyle(color: Colors.white)),
            onTap: () => _loadExample("List Processing", "void main() {\n  var list = [1, 2, 3];\n  var squared = list.map((e) => e * e).toList();\n  print(squared);\n}"),
          ),
          ListTile(
            title: const Text("Async/Await", style: TextStyle(color: Colors.white)),
            onTap: () => _loadExample("Async/Await", "void main() async {\n  print('Waiting...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}"),
          ),
        ],
      ),
    );
  }

  void _loadExample(String title, String code) {
    Navigator.pop(context);
    final fileName = "\\${title.replaceAll(' ', '_').toLowerCase()}.dart";
    ref.read(fileProvider.notifier).importFile(fileName, code);
  }

  Future<void> _copyCode() async {
    if (_codeController != null) {
      await Clipboard.setData(ClipboardData(text: _codeController!.text));
      Fluttertoast.showToast(msg: "Code copied to clipboard", backgroundColor: AppTheme.primaryYellow, textColor: AppTheme.pureBlack);
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && _codeController != null) {
      final currentPos = _codeController!.selection.baseOffset;
      if (currentPos >= 0) {
        final newText = _codeController!.text.replaceRange(
          _codeController!.selection.start,
          _codeController!.selection.end,
          data.text!,
        );
        _codeController!.text = newText;
        _codeController!.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
      } else {
        _codeController!.text = data.text!;
      }
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  Future<void> _shareCode() async {
    if (_codeController != null && _codeController!.text.isNotEmpty) {
      final bytes = utf8.encode(_codeController!.text);
      final base64Code = base64Encode(bytes);
      await Share.share('dartmini://import?code=$base64Code', subject: 'My Dart Code');
    }
  }

  void _deleteFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
