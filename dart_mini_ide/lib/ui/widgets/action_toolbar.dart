import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme.dart';
import '../screens/settings_screen.dart';
import '../../providers/file_provider.dart';
import '../../services/export_service.dart';
import 'package:dart_style/dart_style.dart';

class ActionToolbar extends ConsumerWidget {
  const ActionToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ToolButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _showExamplesDialog(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.format_align_left,
            label: 'Format Code',
            onTap: () => _handleFormat(ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () => _handleImport(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _handleCopy(ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onTap: () => _handleDownload(ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    int counter = ref.read(fileProvider).files.length + 1;
    ref.read(fileProvider.notifier).createFile('untitled\$counter.dart');
    Fluttertoast.showToast(msg: "Created new file");
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'Input / Output': "import 'dart:io';\n\nvoid main() {\n  stdout.write('Enter your name: ');\n  var name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List': "void main() {\n  var list = [1, 2, 3];\n  list.add(4);\n  print(list);\n}",
      'Class': "class Person {\n  String name;\n  Person(this.name);\n  void greet() {\n    print('Hello, my name is \$name');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice');\n  p.greet();\n}",
      'Async': "Future<void> printDelayed() async {\n  await Future.delayed(Duration(seconds: 1));\n  print('Printed after 1 second');\n}\n\nvoid main() async {\n  print('Starting...');\n  await printDelayed();\n  print('Done!');\n}",
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Examples Gallery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...examples.entries.map((e) => ListTile(
                  title: Text(e.key, style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                  onTap: () {
                    ref.read(fileProvider.notifier).createFile('\${e.key.replaceAll(' ', '_').toLowerCase()}.dart', e.value);
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Loaded \${e.key}');
                  },
                )),
          ],
        );
      },
    );
  }

  void _handleFormat(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: "Code formatted successfully");
      } catch (e) {
        Fluttertoast.showToast(msg: "Formatting error: Code might have syntax errors");
      }
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).createFile(name, content);
        Fluttertoast.showToast(msg: "Imported \$name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file");
    }
  }

  void _handleCopy(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  Future<void> _handlePaste(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
       final activeFile = ref.read(fileProvider).activeFile;
       if (activeFile != null) {
         final newContent = '\${activeFile.content}\\n\${data.text!}';
         ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
         Fluttertoast.showToast(msg: "Pasted content");
       }
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        await ExportService.downloadFile(activeFile.name, activeFile.content);
        Fluttertoast.showToast(msg: "Download started");
      } catch (e) {
        Fluttertoast.showToast(msg: "Error downloading file");
      }
    }
  }

  Future<void> _handleShare(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await ExportService.shareText(activeFile.content, 'Code snippet from DartMini IDE');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "\${activeFile.name} deleted");
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.whiteCream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
