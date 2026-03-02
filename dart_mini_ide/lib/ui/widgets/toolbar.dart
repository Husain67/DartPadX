import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/file_provider.dart';
import '../../theme.dart';
import '../settings_screen.dart';

class IDEToolbar extends ConsumerWidget {
  const IDEToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildToolbarButton(
            icon: Icons.note_add_outlined,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).newFile();
            },
          ),
          _buildToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );
              if (result != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
              }
            },
          ),
          _buildToolbarButton(
            icon: Icons.code,
            label: 'Examples',
            onTap: () => _showExamplesDialog(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left_rounded,
            label: 'Format',
            onTap: activeFile == null
                ? null
                : () {
                    ref.read(fileProvider.notifier).formatActiveFile();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code formatted')));
                  },
          ),
          _buildToolbarButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: activeFile == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: activeFile.content));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard')));
                  },
          ),
          _buildToolbarButton(
            icon: Icons.paste_rounded,
            label: 'Paste',
            onTap: activeFile == null
                ? null
                : () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      final currentContent = activeFile.content;
                      ref.read(fileProvider.notifier).updateActiveFileContent('$currentContent\n${data!.text!}');
                    }
                  },
          ),
          _buildToolbarButton(
            icon: Icons.file_download_outlined,
            label: 'Download',
            onTap: activeFile == null
                ? null
                : () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final file = File('${directory.path}/${activeFile.name}');
                    await file.writeAsString(activeFile.content);
                    Share.shareXFiles([XFile(file.path)]);
                  },
          ),
          _buildToolbarButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: activeFile == null
                ? null
                : () {
                    Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
                  },
          ),
          _buildToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.redAccent,
            onTap: activeFile == null
                ? null
                : () {
                    _showDeleteConfirmation(context, ref, activeFile);
                  },
          ),
          _buildToolbarButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: AppTheme.pillDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'Input/Output': 'import "dart:io";\n\nvoid main() {\n  print("Enter name:");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}',
      'List Example': 'void main() {\n  var list = [1, 2, 3];\n  list.add(4);\n  print(list);\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n}\n\nvoid main() {\n  var p = Person("Dart");\n  print(p.name);\n}',
      'Async Example': 'Future<void> main() async {\n  print("Start");\n  await Future.delayed(Duration(seconds: 1));\n  print("End");\n}',
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundStart,
          title: const Text('Code Examples', style: TextStyle(color: AppTheme.primaryAccent)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: examples.length,
              itemBuilder: (context, index) {
                String title = examples.keys.elementAt(index);
                String code = examples.values.elementAt(index);
                return ListTile(
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  onTap: () {
                    ref.read(fileProvider.notifier).importFile('${title.replaceAll(' ', '_')}.dart', code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, dynamic file) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundEnd,
          title: const Text('Delete File', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Delete this file? This cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(file);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File deleted'), backgroundColor: Colors.redAccent),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
