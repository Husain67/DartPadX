import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/editor_provider.dart';
import '../settings/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          _buildButton(
            context,
            icon: Icons.lightbulb_outline,
            label: 'Examples',
            onTap: () => _showExamples(context, ref),
          ),
          _buildButton(
            context,
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _handleFormat(ref),
          ),
          _buildButton(
            context,
            icon: Icons.note_add_outlined,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildButton(
            context,
            icon: Icons.file_download_outlined,
            label: 'Import .dart',
            onTap: () => _handleImport(context, ref),
          ),
          _buildButton(
            context,
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _handleCopy(ref),
          ),
          _buildButton(
            context,
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(ref),
          ),
          _buildButton(
            context,
            icon: Icons.download,
            label: 'Download .dart',
            onTap: () => _handleDownload(ref),
          ),
          _buildButton(
            context,
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(ref),
          ),
          _buildButton(
            context,
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
            onTap: () => _handleDelete(context, ref),
          ),
          _buildButton(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'List Example': "void main() {\n  var list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  Person(this.name);\n  void greet() {\n    print('Hello, \$name');\n  }\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.greet();\n}",
      'Async Example': "Future<void> main() async {\n  print('Waiting...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}",
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: examples.entries.map((e) => ListTile(
            title: Text(e.key, style: const TextStyle(color: Colors.white)),
            onTap: () {
              ref.read(editorProvider.notifier).addFile('${e.key.replaceAll(" ", "_").toLowerCase()}.dart', e.value);
              Navigator.pop(context);
            },
          )).toList(),
        );
      }
    );
  }

  void _handleFormat(WidgetRef ref) {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(editorProvider.notifier).updateActiveFileContent(formatted);
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Format failed (syntax error)');
      }
    }
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Filename (e.g. script.dart)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(editorProvider.notifier).addFile(controller.text.trim(), '');
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final content = utf8.decode(file.bytes!);
          ref.read(editorProvider.notifier).addFile(file.name, content);
          Fluttertoast.showToast(msg: 'File imported successfully');
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    }
  }

  void _handleCopy(WidgetRef ref) {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _handlePaste(WidgetRef ref) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final activeFile = ref.read(editorProvider).activeFile;
      if (activeFile != null) {
        final newContent = activeFile.content + data.text!;
        ref.read(editorProvider.notifier).updateActiveFileContent(newContent);
        Fluttertoast.showToast(msg: 'Pasted from clipboard');
      }
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = '${dir.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: 'Saved to $path');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Download failed: $e');
    }
  }

  void _handleShare(WidgetRef ref) {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Shared from DartMini IDE');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(editorProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(editorProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
