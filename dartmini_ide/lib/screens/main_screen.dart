import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                color: DartMiniTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : () => _runCode(ref),
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DartMiniTheme.primaryAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: DartMiniTheme.backgroundGradient,
        child: Column(
          children: [
            _buildToolbar(context, ref),
            _buildFileTabs(ref, fileState),
            const Expanded(
              child: Stack(
                children: [
                  CodeEditorWidget(),
                  OutputSheet(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ToolbarButton(label: 'New File', icon: Icons.insert_drive_file, onPressed: () => _newFile(ref)),
          ToolbarButton(label: 'Import .dart', icon: Icons.download, onPressed: () => _importFile(ref)),
          ToolbarButton(label: 'Copy code', icon: Icons.copy, onPressed: () => _copyCode(ref)),
          ToolbarButton(label: 'Paste', icon: Icons.paste, onPressed: () => _pasteCode(ref)),
          ToolbarButton(label: 'Format', icon: Icons.format_align_left, onPressed: () => _formatCode(ref)),
          ToolbarButton(label: 'Download .dart', icon: Icons.file_download, onPressed: () => _downloadFile(ref)),
          ToolbarButton(label: 'Share', icon: Icons.share, onPressed: () => _shareCode(ref)),
          ToolbarButton(label: 'Examples', icon: Icons.book, onPressed: () => _showExamples(context, ref)),
          ToolbarButton(label: 'Delete', icon: Icons.delete, onPressed: () => _deleteFile(context, ref)),
          ToolbarButton(label: 'Settings', icon: Icons.settings, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  void _formatCode(WidgetRef ref) {
    // Note: formatting usually requires a formatter like dart_style, which does not run well in browser
    // or requires significant setup. Here we provide a simple generic code cleanup for demo.
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file != null) {
      final formatted = file.content.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: 'Code format triggered');
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DartMiniTheme.surfaceColor,
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples Gallery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListTile(title: const Text('Hello World'), onTap: () => _loadExample(ctx, ref, 'hello_world.dart', "void main() {\n  print('Hello World!');\n}")),
            ListTile(title: const Text('List'), onTap: () => _loadExample(ctx, ref, 'list_example.dart', "void main() {\n  var list = [1, 2, 3];\n  print(list);\n}")),
            ListTile(title: const Text('Class'), onTap: () => _loadExample(ctx, ref, 'class_example.dart', "class Person {\n  String name;\n  Person(this.name);\n}\nvoid main() {\n  var p = Person('Alice');\n  print(p.name);\n}")),
            ListTile(title: const Text('Async'), onTap: () => _loadExample(ctx, ref, 'async_example.dart', "void main() async {\n  print('Start');\n  await Future.delayed(Duration(seconds: 1));\n  print('End');\n}")),
          ],
        );
      }
    );
  }

  void _loadExample(BuildContext context, WidgetRef ref, String name, String content) {
    ref.read(fileProvider.notifier).addFile(name, content);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Loaded $name');
  }

  Widget _buildFileTabs(WidgetRef ref, FileState state) {
    return Container(
      height: 40,
      color: const Color(0xFF222222),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2B2B2B) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? DartMiniTheme.primaryAccent : Colors.transparent,
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteFileWithId(context, ref, file.id),
                    child: const Icon(Icons.close, size: 16, color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _runCode(WidgetRef ref) {
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file != null) {
      ref.read(executionProvider.notifier).executeCode(file.content, '');
    }
  }

  void _newFile(WidgetRef ref) {
    ref.read(fileProvider.notifier).addFile('untitled${ref.read(fileProvider).files.length}.dart', '');
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final content = utf8.decode(result.files.single.bytes!);
      ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
    }
  }

  void _copyCode(WidgetRef ref) {
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file != null) {
      Clipboard.setData(ClipboardData(text: file.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: 'Code pasted');
    }
  }

  void _downloadFile(WidgetRef ref) {
    // Note: In a real mobile app, this would use path_provider to save to Downloads.
    // For this demonstration, we just show a toast as downloading requires platform-specific implementations.
    Fluttertoast.showToast(msg: 'Download feature requires platform specific setup.');
  }

  void _shareCode(WidgetRef ref) {
    final file = ref.read(fileProvider.notifier).activeFile;
    if (file != null) {
      Share.share(file.content, subject: 'Dart Code: ${file.name}');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeId = ref.read(fileProvider).activeFileId;
    if (activeId != null) {
      _deleteFileWithId(context, ref, activeId);
    }
  }

  void _deleteFileWithId(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              // Set active to the one to delete, then delete
              ref.read(fileProvider.notifier).setActiveFile(id);
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
