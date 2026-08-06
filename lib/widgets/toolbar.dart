import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/editor_provider.dart';

import '../screens/settings_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            context,
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _showExamples(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.add,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.download_rounded,
            label: 'Import',
            onTap: () => _handleImport(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _handleCopy(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.auto_awesome,
            label: 'Format',
            onTap: () => _handleFormat(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.save_alt,
            label: 'Download',
            onTap: () => _handleDownload(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(context, ref),
          ),
          _buildToolbarButton(
            context,
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
            isDanger: true,
          ),
          _buildToolbarButton(
            context,
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

  Widget _buildToolbarButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.toolbarButtonBorder),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isDanger ? Colors.red : AppTheme.toolbarIconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDanger ? Colors.red : AppTheme.toolbarIconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List Example': "void main() {\n  final list = [1, 2, 3, 4, 5];\n  for (var num in list) {\n    print(num * 2);\n  }\n}",
      'Class Example': "class Person {\n  final String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name');\n}\n\nvoid main() {\n  final p = Person('DartMini');\n  p.greet();\n}",
      'Async Example': "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Data fetched!');\n}"
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examples Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key),
              onTap: () async {
                final name = '${e.key.replaceAll(' ', '_').toLowerCase()}.dart';
                await ref.read(editorProvider.notifier).createFile(name);
                await ref.read(editorProvider.notifier).updateActiveFileContent(e.value);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                _showToast('Loaded ${e.key}');
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  Future<void> _handleNewFile(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. script.dart'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      String finalName = name;
      if (!finalName.endsWith('.dart')) { finalName = '$finalName.dart'; }
      await ref.read(editorProvider.notifier).createFile(finalName);
      _showToast('Created $finalName');
    }
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt', 'json'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final content = String.fromCharCodes(result.files.single.bytes!);
        final name = result.files.single.name;

        await ref.read(editorProvider.notifier).createFile(name);
        await ref.read(editorProvider.notifier).updateActiveFileContent(content);
        _showToast('Imported $name');
      }
    } catch (e) {
      _showToast('Import failed: $e');
    }
  }

  Future<void> _handleCopy(BuildContext context, WidgetRef ref) async {
    final active = ref.read(editorProvider).activeFile;
    if (active != null) {
      await Clipboard.setData(ClipboardData(text: active.content));
      _showToast('Copied to clipboard');
    }
  }

  Future<void> _handlePaste(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      // In a real app we might insert at cursor, but here we'll just replace or append
      // For simplicity, let's just append or replace
      final active = ref.read(editorProvider).activeFile;
      if (active != null) {
        final newContent = "${active.content}${data?.text ?? ''}";
        await ref.read(editorProvider.notifier).updateActiveFileContent(newContent);
        _showToast('Pasted from clipboard');
      }
    }
  }

  Future<void> _handleFormat(BuildContext context, WidgetRef ref) async {
    final active = ref.read(editorProvider).activeFile;
    if (active != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formatted = formatter.format(active.content);
        await ref.read(editorProvider.notifier).updateActiveFileContent(formatted);
        _showToast('Code formatted');
      } catch (e) {
        _showToast('Syntax error, could not format');
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final active = ref.read(editorProvider).activeFile;
    if (active == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        directory = dirs?.first;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/${active.name}');
        await file.writeAsString(active.content);
        _showToast('Saved to ${file.path}');
      }
    } catch (e) {
      _showToast('Download failed: $e');
    }
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final active = ref.read(editorProvider).activeFile;
    if (active != null) {
      await Share.share(active.content, subject: 'Shared from DartMini IDE: ${active.name}');
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final active = ref.read(editorProvider).activeFile;
    if (active == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: Text('Are you sure you want to delete ${active.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(editorProvider.notifier).deleteActiveFile();
      _showToast('File deleted');
    }
  }
}
