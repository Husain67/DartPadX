import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_mini_ide/screens/settings_screen.dart';
import 'package:dart_style/dart_style.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.note_add,
            label: 'New',
            onTap: () => ref.read(fileProvider.notifier).newFile(),
          ),
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
                withData: true,
              );
              if (result != null && result.files.single.bytes != null) {
                final content = String.fromCharCodes(result.files.single.bytes!);
                final name = result.files.single.name;
                ref.read(fileProvider.notifier).importFile(name, content);
                Fluttertoast.showToast(msg: 'File imported');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              final active = ref.read(fileProvider).activeFile;
              if (active != null) {
                Clipboard.setData(ClipboardData(text: active.content));
                Fluttertoast.showToast(msg: 'Copied to clipboard');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
                Fluttertoast.showToast(msg: 'Pasted from clipboard');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final active = ref.read(fileProvider).activeFile;
              if (active != null) {
                Share.share(active.content, subject: 'Dart Code from DartMini IDE');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.auto_awesome,
            label: 'Examples',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Examples Gallery'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: const Text('Hello World'),
                          onTap: () {
                            ref.read(fileProvider.notifier).importFile('hello.dart', "void main() {\n  print('Hello, World!');\n}");
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Input/Output'),
                          onTap: () {
                            ref.read(fileProvider.notifier).importFile('io.dart', "import 'dart:io';\n\nvoid main() {\n  print('Enter something:');\n  String? input = stdin.readLineSync();\n  print('You entered: \$input');\n}");
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('List'),
                          onTap: () {
                            ref.read(fileProvider.notifier).importFile('list.dart', "void main() {\n  var list = [1, 2, 3];\n  for (var item in list) {\n    print(item);\n  }\n}");
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Class'),
                          onTap: () {
                            ref.read(fileProvider.notifier).importFile('class.dart', "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hello, \$name');\n}\n\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}");
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          title: const Text('Async'),
                          onTap: () {
                            ref.read(fileProvider.notifier).importFile('async.dart', "Future<void> main() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}");
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final active = ref.read(fileProvider).activeFile;
              if (active != null) {
                try {
                  final formatted = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(active.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                  Fluttertoast.showToast(msg: 'Code formatted');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Format error: ${e.toString()}');
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete File?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(fileProvider.notifier).deleteActiveFile();
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: 'File deleted');
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          _ToolbarButton(
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
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
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
}
