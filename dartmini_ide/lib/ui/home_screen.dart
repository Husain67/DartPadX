import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import 'theme.dart';
import 'widgets/toolbar_button.dart';
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
    final content = activeFile?.content ?? '';

    _codeController?.dispose();
    _codeController = CodeController(
      text: content,
      language: dart,
    );

    _codeController!.addListener(() {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null && activeFile.content != _codeController!.text) {
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

  void _handleTabSwitch(String fileName) {
    ref.read(fileProvider.notifier).setActiveFile(fileName);
    final content = ref.read(fileProvider).files.firstWhere((f) => f.name == fileName).content;

    // update controller text safely without recreating
    if (_codeController!.text != content) {
      _codeController!.text = content;
    }
  }

  void _runCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    ref.read(compilerProvider.notifier).executeCode(
      activeFile.content,
      stdin: _stdinController.text,
    );
    _showOutputBottomSheet();
  }

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).addNewFile(name, content);
        _handleTabSwitch(name);
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  void _copyCode() {
    if (_codeController != null) {
      Clipboard.setData(ClipboardData(text: _codeController!.text));
      Fluttertoast.showToast(msg: "Code copied");
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && _codeController != null) {
      final selection = _codeController!.selection;
      final text = _codeController!.text;

      String newText;
      if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
        newText = text.replaceRange(selection.start, selection.end, data.text!);
      } else {
        newText = text + data.text!;
      }

      _codeController!.text = newText;
      Fluttertoast.showToast(msg: "Code pasted");
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        dir = dirs?.first;
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = "\${dir.path}/\${activeFile.name}";
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

  void _deleteCurrentFile() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(fileProvider.notifier).deleteFile(activeFile.name);
              final newActive = ref.read(fileProvider).activeFile;
              if (newActive != null) {
                 _codeController?.text = newActive.content;
              }
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _formatCode() {
    if (_codeController == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(_codeController!.text);
      _codeController!.text = formatted;
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format");
    }
  }

  void _showOutputBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOutputSheet(),
    );
  }

  Widget _buildOutputSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: AppTheme.gradientBackground.copyWith(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final compState = ref.watch(compilerProvider);
                    if (compState.isExecuting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
                      );
                    }
                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (compState.error.isNotEmpty) ...[
                          const Text('Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text(compState.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                          const SizedBox(height: 16),
                        ],
                        if (compState.stderr.isNotEmpty) ...[
                          const Text('STDERR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          Text(compState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                          const SizedBox(height: 16),
                        ],
                        const Text('STDOUT', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(compState.stdout.isEmpty && compState.error.isEmpty && compState.stderr.isEmpty ? 'No output' : compState.stdout,
                             style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (compState.time.isNotEmpty) Text('Time: \${compState.time}s', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 16),
                            if (compState.memory.isNotEmpty) Text('Memory: \${compState.memory}', style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    return Scaffold(
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
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: InkWell(
                onTap: _runCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          if (ref.watch(compilerProvider).isExecuting) {
                            return const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            );
                          }
                          return const Icon(Icons.play_arrow, color: Colors.black, size: 20);
                        }
                      ),
                      const SizedBox(width: 4),
                      const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  ToolbarButton(label: 'New File', onPressed: () => _handleTabSwitch('untitled_\${DateTime.now().millisecondsSinceEpoch}.dart')), // Simple new file logic for demo
                  ToolbarButton(label: '📥 Import .dart', onPressed: _importFile),
                  ToolbarButton(label: '📋 Copy code', onPressed: _copyCode),
                  ToolbarButton(label: '📝 Paste', onPressed: _pasteCode),
                  ToolbarButton(label: '⬇️ Download .dart', onPressed: _downloadFile),
                  ToolbarButton(label: '🔗 Share', onPressed: _shareCode),
                  ToolbarButton(label: '🗑️ Delete current file', onPressed: _deleteCurrentFile),
                  ToolbarButton(label: '✨ Format', onPressed: _formatCode),
                  ToolbarButton(label: '⚙️ Settings', onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),

            // Stdin input field (optional)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _stdinController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'STDIN (optional)',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),

            // File Tabs
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fileState.files.length,
                itemBuilder: (context, index) {
                  final file = fileState.files[index];
                  final isActive = file.name == fileState.activeFileName;
                  return GestureDetector(
                    onTap: () => _handleTabSwitch(file.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white10 : Colors.transparent,
                        border: Border(bottom: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 2)),
                      ),
                      child: Text(file.name, style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
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
                            textStyle: TextStyle(color: Colors.white54, height: 1.5),
                            showLineNumbers: true,
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
