import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../../utils/theme.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _fileNameController = TextEditingController();

  void _createNewFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: _fileNameController,
          decoration: const InputDecoration(hintText: 'Enter file name (e.g. test.dart)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_fileNameController.text.isNotEmpty) {
                ref.read(fileProvider.notifier).createFile(_fileNameController.text);
                _fileNameController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).createFile(result.files.single.name);
      // Wait for UI to update active file
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        ref.read(fileProvider.notifier).updateActiveFileContent(content);
      });
    }
  }

    void _copyCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  void _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null) {
        final newContent = activeFile.content + data.text!;
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        Fluttertoast.showToast(msg: 'Code pasted');
      }
    }
  }

  void _formatCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        final formatted = formatter.format(activeFile.content);
        // Force provider update to trigger controller sync
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        // For flutter_code_editor controller sync we copy list state:
        ref.read(fileProvider.notifier).forceUpdate();
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error: format failed');
      }
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: activeFile.name);
    }
  }

  void _deleteCurrentFile() {
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
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadFile() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: 'Saved to $path');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving file: $e');
    }
  }

  Widget _buildToolbarButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: DartMiniTheme.surface,
        border: Border.all(color: Colors.white24, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: DartMiniTheme.textMain, size: 20),
          ),
        ),
      ),
    );
  }

  void _showExamples() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: DartMiniTheme.surface,
          child: ListView(
            children: [
              const ListTile(title: Text('Examples Gallery', style: TextStyle(color: DartMiniTheme.primary, fontWeight: FontWeight.bold))),
              ListTile(
                title: const Text('Hello World'),
                onTap: () {
                  ref.read(fileProvider.notifier).createFile('hello_world.dart');
                  ref.read(fileProvider.notifier).updateActiveFileContent('void main() {\n  print("Hello World!");\n}');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Input/Output'),
                onTap: () {
                  ref.read(fileProvider.notifier).createFile('io.dart');
                  ref.read(fileProvider.notifier).updateActiveFileContent('import "dart:io";\n\nvoid main() {\n  String? input = stdin.readLineSync();\n  print("You said: \$input");\n}');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Async/Await'),
                onTap: () {
                  ref.read(fileProvider.notifier).createFile('async.dart');
                  ref.read(fileProvider.notifier).updateActiveFileContent('void main() async {\n  print("Waiting...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Done!");\n}');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: DartMiniTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : () => ref.read(executionProvider.notifier).runCode(),
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(execState.isRunning ? 'Running...' : 'Run'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // File Tabs
          SizedBox(
            height: 40,
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? DartMiniTheme.surface : Colors.transparent,
                      border: Border(bottom: BorderSide(color: isActive ? DartMiniTheme.primary : Colors.transparent, width: 2)),
                    ),
                    child: Text(file.name, style: TextStyle(color: isActive ? DartMiniTheme.primary : DartMiniTheme.textMuted)),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Toolbar
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildToolbarButton(icon: Icons.add, tooltip: 'New File', onTap: _createNewFile),
                _buildToolbarButton(icon: Icons.file_download, tooltip: 'Import', onTap: _importFile),
                _buildToolbarButton(icon: Icons.copy, tooltip: 'Copy', onTap: _copyCode),
                _buildToolbarButton(icon: Icons.paste, tooltip: 'Paste', onTap: _pasteCode),
                _buildToolbarButton(icon: Icons.format_align_left, tooltip: 'Format', onTap: _formatCode),
                _buildToolbarButton(icon: Icons.save_alt, tooltip: 'Download', onTap: _downloadFile),
                _buildToolbarButton(icon: Icons.share, tooltip: 'Share', onTap: _shareCode),
                _buildToolbarButton(icon: Icons.delete_outline, tooltip: 'Delete', onTap: _deleteCurrentFile),
                _buildToolbarButton(icon: Icons.lightbulb_outline, tooltip: 'Examples', onTap: _showExamples),
                _buildToolbarButton(icon: Icons.settings, tooltip: 'Settings', onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
              ],
            ),
          ),
          // Editor Area
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CodeEditorWidget(),
                ),
                const OutputSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
