// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
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
      language: dart,
    );

    _codeController.addListener(() {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null && activeFile.content != _codeController.text) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCodeController();
    });
  }

  void _syncCodeController() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && _codeController.text != activeFile.content) {
      _codeController.text = activeFile.content;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeIndex != next.activeIndex) {
        _syncCodeController();
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        backgroundColor: AppTheme.appBarColor,
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
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              icon: execState.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: execState.isLoading
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).executeCode(_codeController.text, _stdinController.text);
                      _showOutputBottomSheet(context);
                    },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            _buildToolbar(),
            _buildFileTabs(fileState),
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(styles: darculaTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(textStyle: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).addFile('untitled_${DateTime.now().millisecondsSinceEpoch}.dart', '');
              Fluttertoast.showToast(msg: 'New file created');
            },
          ),
          ToolbarButton(
            icon: Icons.file_download,
            label: 'Import .dart',
            onTap: _importFile,
          ),
          ToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: _codeController.text));
              Fluttertoast.showToast(msg: 'Copied to clipboard');
            },
          ),
          ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                _codeController.text = data!.text!;
                Fluttertoast.showToast(msg: 'Pasted');
              }
            },
          ),
          ToolbarButton(
            icon: Icons.download,
            label: 'Download .dart',
            onTap: _downloadFile,
          ),
          ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _shareCode,
          ),
          ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              // Basic formatting (flutter_code_editor lacks built in format)
              // This is a minimal formatting feature as a real formatter requires external heavy dart_style package
              final text = _codeController.text;
              _codeController.text = text.replaceAll(';', ';\n').replaceAll('{', '{\n').replaceAll('}', '}\n');
              Fluttertoast.showToast(msg: 'Code Formatted');
            },
          ),
          ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _confirmDelete(),
          ),
          ToolbarButton(
            icon: Icons.menu_book,
            label: 'Examples Gallery',
            onTap: _showExamplesGallery,
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

  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        String fileName = result.files.single.name;
        ref.read(fileProvider.notifier).addFile(fileName, contents);
        Fluttertoast.showToast(msg: 'File imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing file: $e');
    }
  }

  Future<void> _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${activeFile.name}');
      await file.writeAsString(_codeController.text);
      Fluttertoast.showToast(msg: 'Saved to ${file.path}');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading file: $e');
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;
    Share.share(_codeController.text, subject: 'Dart Code: ${activeFile.name}');
  }

  void _showExamplesGallery() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceColor,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Examples Gallery', style: TextStyle(fontSize: 20, color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.grey),
              ListTile(
                title: const Text('Hello World'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('hello_world.dart', "void main() {\n  print('Hello World!');\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Input/Output (stdin)'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('io_example.dart', "import 'dart:io';\n\nvoid main() {\n  print('Enter something:');\n  String? input = stdin.readLineSync();\n  print('You entered: \$input');\n}");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Async/Await'),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('async_example.dart', "import 'dart:async';\n\nFuture<void> main() async {\n  print('Waiting 2 seconds...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Done!');\n}");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileTabs(FileState state) {
    if (state.files.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = index == state.activeIndex;

          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(right: 2, top: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.surfaceColor : Colors.black45,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(
                  top: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 2),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showOutputBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final execState = ref.watch(executionProvider);
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 16.0),
                            child: Text('Output Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.clear_all, color: Colors.white),
                                tooltip: 'Clear Output',
                                onPressed: () {
                                  ref.read(executionProvider.notifier).clearOutput();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          )
                        ],
                      ),
                      const Divider(color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _stdinController,
                          decoration: const InputDecoration(
                            labelText: 'Standard Input (stdin)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (execState.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              if (execState.stdout.isNotEmpty)
                                Text(execState.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                              if (execState.stderr.isNotEmpty)
                                Text(execState.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                              if (execState.executionTime.isNotEmpty || execState.memory.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Text(
                                    'Time: ${execState.executionTime} | Memory: ${execState.memory}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
