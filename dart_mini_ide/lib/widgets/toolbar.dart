import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.add_circle_outline,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
            },
          ),
          _ToolbarButton(
            icon: Icons.file_download_outlined,
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
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                await Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Code copied!");
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                final currentContent = ref.read(fileProvider).activeFile?.content ?? '';
                ref.read(fileProvider.notifier).updateActiveFileContent(currentContent + data.text!, isExternal: true);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.download_outlined,
            label: 'Download .dart',
            onTap: () async {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File('\${directory.path}/\${activeFile.name}');
                  await file.writeAsString(activeFile.content);
                  await Share.shareXFiles([XFile(file.path)], text: 'Download \${activeFile.name}');
               }
            },
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format Code',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter();
                  final formatted = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formatted, isExternal: true);
                  Fluttertoast.showToast(msg: "Code formatted");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Format failed (syntax error)");
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete file',
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: AppTheme.backgroundEnd,
                    title: const Text('Delete this file?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteActiveFile();
                          Navigator.of(context).pop();
                          Fluttertoast.showToast(msg: "File deleted");
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          _ToolbarButton(
            icon: Icons.library_books,
            label: 'Examples',
            onTap: () {
              _showExamples(context, ref);
            },
          ),
          _ToolbarButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print(\'Hello, World!\');\n}\n',
      'Input/Output': 'import \'dart:io\';\n\nvoid main() {\n  stdout.write(\'Enter your name: \');\n  String? name = stdin.readLineSync();\n  print(\'Hello, \$name!\');\n}\n',
      'List & Loop': 'void main() {\n  List<String> fruits = [\'Apple\', \'Banana\', \'Cherry\'];\n  for (var fruit in fruits) {\n    print(fruit);\n  }\n}\n',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print(\'Hi, I am \$name\');\n}\n\nvoid main() {\n  var p = Person(\'Dart\');\n  p.greet();\n}\n',
      'Async Example': 'Future<void> main() async {\n  print(\'Fetching data...\');\n  await Future.delayed(Duration(seconds: 2));\n  print(\'Data fetched!\');\n}\n',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundEnd,
      builder: (BuildContext context) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(
              child: ListView(
                children: examples.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      ref.read(fileProvider.notifier).importFile('\${entry.key.replaceAll(" ", "_")}.dart', entry.value);
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: "Example loaded");
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: label,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.toolbarButtonBg,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white24, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              // Optional: hide label on very small screens or just keep icon
            ],
          ),
        ),
      ),
    );
  }
}
