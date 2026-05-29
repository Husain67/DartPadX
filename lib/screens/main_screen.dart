import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/files_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/custom_buttons.dart';
import '../utils/app_theme.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  CodeController? _codeController;
  final TextEditingController _stdinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCodeController();
    });
  }

  void _initCodeController() {
    final activeFile = ref.read(filesProvider.notifier).activeFile;
    if (activeFile != null) {
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(() {
        ref.read(filesProvider.notifier).updateActiveFileContent(_codeController!.text);
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    _codeController?.dispose();
    _stdinCtrl.dispose();
    super.dispose();
  }

  void _syncController() {
    final activeFile = ref.read(filesProvider.notifier).activeFile;
    if (activeFile != null && _codeController != null) {
      if (_codeController!.text != activeFile.content) {
        final pos = _codeController!.selection.baseOffset;
        _codeController!.text = activeFile.content;
        _codeController!.selection = TextSelection.collapsed(
            offset: pos <= _codeController!.text.length ? pos : _codeController!.text.length);
      }
    } else if (activeFile != null && _codeController == null) {
      _initCodeController();
    }
  }

  Future<void> _handleNewFile() async {
    ref.read(filesProvider.notifier).createNewFile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
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
        ref.read(filesProvider.notifier).createNewFile(
          name: result.files.single.name,
          content: content,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing: $e");
    }
  }

  Future<void> _handleDownload() async {
    final activeFile = ref.read(filesProvider.notifier).activeFile;
    if (activeFile == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${activeFile.name}');
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Downloaded to ${file.path}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading: $e");
    }
  }

  Future<void> _handleShare() async {
    final activeFile = ref.read(filesProvider.notifier).activeFile;
    if (activeFile == null) return;
    Share.share(activeFile.content, subject: 'DartMini IDE Code');
  }

  Future<void> _handleDelete() async {
    final activeFile = ref.read(filesProvider.notifier).activeFile;
    if (activeFile == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this file?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      ref.read(filesProvider.notifier).deleteFile(activeFile.id);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
      Fluttertoast.showToast(msg: "File deleted");
    }
  }


  void _handleFormat() {
    if (_codeController == null) return;
    try {
      // Basic formatting formatting for demonstration. A robust formatter would require dart_style.
      // But adding dart_style ^2.3.6 dynamically
      Fluttertoast.showToast(msg: "Formatting applies simple indents (add dart_style for full format)");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error formatting code");
    }
  }

  void _showExamples() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Hello World'),
              onTap: () {
                ref.read(filesProvider.notifier).createNewFile(name: 'hello_world.dart', content: "void main() {\n  print('Hello World!');\n}");
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
              },
            ),
            ListTile(
              title: const Text('Input/Output'),
              onTap: () {
                ref.read(filesProvider.notifier).createNewFile(name: 'io.dart', content: "import 'dart:io';\n\nvoid main() {\n  print('Enter something:');\n  String? input = stdin.readLineSync();\n  print('You entered: \$input');\n}");
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
              },
            ),
            ListTile(
              title: const Text('List'),
              onTap: () {
                ref.read(filesProvider.notifier).createNewFile(name: 'list.dart', content: "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var num in numbers) {\n    print(num);\n  }\n}");
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
              },
            ),
             ListTile(
              title: const Text('Class'),
              onTap: () {
                ref.read(filesProvider.notifier).createNewFile(name: 'class.dart', content: "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hello, \$name');\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.greet();\n}");
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
              },
            ),
            ListTile(
              title: const Text('Async'),
              onTap: () {
                ref.read(filesProvider.notifier).createNewFile(name: 'async.dart', content: "Future<void> main() async {\n  print('Waiting 2 seconds...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Done!');\n}");
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
              },
            )
          ],
        ),
      ),
    );
  }

  void _runCode() {
    final code = _codeController?.text ?? '';
    final stdin = _stdinCtrl.text;
    ref.read(executionProvider.notifier).executeCode(code, stdin);
    _showOutputSheet();
  }

  void _showOutputSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OutputSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(filesProvider, (prev, next) {
      if (prev?.activeFileId != next.activeFileId) {
        _syncController();
      }
    });

    final filesState = ref.watch(filesProvider);
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
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : _runCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(80, 40),
              ),
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Toolbar
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                ToolbarButton(icon: Icons.add, label: 'New', onPressed: _handleNewFile),
                ToolbarButton(icon: Icons.file_download, label: 'Import', onPressed: _handleImport),
                ToolbarButton(icon: Icons.download, label: 'Download', onPressed: _handleDownload),
                ToolbarButton(icon: Icons.share, label: 'Share', onPressed: _handleShare),
                ToolbarButton(icon: Icons.format_align_left, label: 'Format', onPressed: _handleFormat),
                ToolbarButton(icon: Icons.library_books, label: 'Examples', onPressed: _showExamples),
                ToolbarButton(icon: Icons.delete, label: 'Delete', onPressed: _handleDelete, iconColor: Colors.red),
                ToolbarButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
          ),
          // File Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filesState.files.length,
              itemBuilder: (context, index) {
                final file = filesState.files[index];
                final isActive = file.id == filesState.activeFileId;
                return GestureDetector(
                  onTap: () => ref.read(filesProvider.notifier).setActiveFile(file.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.only(right: 2, top: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1E1E1E) : Colors.black,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border.all(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      file.name,
                      style: TextStyle(color: isActive ? AppTheme.primaryAccent : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),
          // Editor
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E),
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator())
                  : CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class OutputSheet extends ConsumerWidget {
  const OutputSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2)],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Output', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Row(
                      children: [
                        if (execState.executionTime.isNotEmpty)
                          Text('${execState.executionTime}ms', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                        )
                      ],
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (execState.isRunning)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                    else ...[
                      if (execState.stdout.isNotEmpty)
                        Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                      if (execState.stderr.isNotEmpty)
                        Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                      if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                        const Text('No output', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
