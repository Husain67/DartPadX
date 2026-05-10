import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Colors.transparent,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => ref.read(fileProvider.notifier).createNewFile(),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.file_download,
            label: 'Import .dart',
            onTap: () => _importFile(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _copyCode(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _formatCode(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.library_books,
            label: 'Examples',
            onTap: () => _showExamplesGallery(context, ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.download,
            label: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _deleteFile(context, ref),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5E5), // white/cream background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      ref.read(fileProvider.notifier).createNewFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: 'File imported');
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      ref.read(fileProvider.notifier).forceUpdate();
      Fluttertoast.showToast(msg: 'Pasted from clipboard');
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final path = '${directory.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: 'Saved to $path');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to save: $e');
    }
  }


  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        ref.read(fileProvider.notifier).forceUpdate();
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Format failed (Syntax Error?)');
      }
    }
  }

  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List': "void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for (var num in numbers) {\n    print(num * 2);\n  }\n}",
      'Class': "class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void introduce() {\n    print('Hi, I am \$name, \$age years old.');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 28);\n  p.introduce();\n}",
      'Async': "Future<void> fetchData() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data loaded!');\n}\n\nvoid main() async {\n  await fetchData();\n}",
    };

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          color: const Color(0xFF1A1A1A),
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              ...examples.entries.map((e) => ListTile(
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () {
                  ref.read(fileProvider.notifier).createNewFile('${e.key.replaceAll(' ', '_').toLowerCase()}.dart', e.value);
                  Navigator.pop(ctx);
                  Fluttertoast.showToast(msg: 'Loaded ${e.key}');
                },
              )),
            ],
          ),
        );
      }
    );
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      final shareUrl = 'dartmini://share?code=$base64Code';
      Share.share('Check out my Dart code on DartMini: $shareUrl');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: Text('Delete "${activeFile.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'File deleted');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
