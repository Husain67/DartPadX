import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format_utils.dart';
import '../screens/settings_screen.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _createNewFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: 'Import .dart',
            onTap: () => _importFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _copyCode(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onTap: () => _downloadFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.auto_fix_high,
            label: 'Format Code',
            onTap: () => _formatCode(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.list_alt,
            label: 'Examples',
            onTap: () => _showExamples(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: 'Delete file',
            onTap: () => _deleteCurrentFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createNewFile(BuildContext context, WidgetRef ref) {
    ref.read(fileProvider.notifier).createFile('untitled.dart');
    Fluttertoast.showToast(msg: "New file created");
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        ref.read(fileProvider.notifier).createFile(name, content: content);
        Fluttertoast.showToast(msg: "File imported: $name");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  void _copyCode(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        String newContent = activeFile.content + data.text!;
        ref.read(fileProvider.notifier).updateContent(newContent);
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  Future<void> _downloadFile(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/${activeFile.name}';
        final file = File(filePath);
        await file.writeAsString(activeFile.content);

        await Share.shareXFiles([XFile(filePath)], text: 'Download ${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: "Error downloading file: $e");
      }
    }
  }

  Future<void> _shareCode(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Share.share(activeFile.content, subject: 'Shared from DartMini IDE: ${activeFile.name}');
    }
  }

  void _formatCode(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        String formatted = FormatUtils.formatDartCode(activeFile.content);
        ref.read(fileProvider.notifier).updateContent(formatted);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Could not format: Syntax error");
      }
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureBlack,
        title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _ExampleTile(
                title: 'Hello World',
                code: "void main() {\n  print('Hello World!');\n}",
                ref: ref,
              ),
              _ExampleTile(
                title: 'Input/Output',
                code: "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, $name!');\n}",
                ref: ref,
              ),
              _ExampleTile(
                title: 'List Example',
                code: "void main() {\n  var list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}",
                ref: ref,
              ),
              _ExampleTile(
                title: 'Class Example',
                code: "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hello, $name');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}",
                ref: ref,
              ),
              _ExampleTile(
                title: 'Async Example',
                code: "Future<void> fetch() async {\n  await Future.delayed(Duration(seconds: 1));\n  print('Fetched');\n}\n\nvoid main() async {\n  print('Start');\n  await fetch();\n  print('End');\n}",
                ref: ref,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.primaryYellow)),
          ),
        ],
      ),
    );
  }

  void _deleteCurrentFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.pureBlack,
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${activeFile.name}? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final String title;
  final String code;
  final WidgetRef ref;

  const _ExampleTile({required this.title, required this.code, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryYellow),
      onTap: () {
        ref.read(fileProvider.notifier).createFile('${title.replaceAll(' ', '_').toLowerCase()}.dart', content: code);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Loaded $title");
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.toolbarBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.toolbarBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppTheme.pureBlack),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.pureBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
