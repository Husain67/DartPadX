import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';

import '../providers/file_provider.dart';
import '../core/theme.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final activeFile = ref.read(fileProvider.notifier).activeFile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.backgroundStart,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [

          _buildPillButton(
            icon: Icons.library_books,
            label: 'Examples',
            onTap: () {
              _showExamples(context, ref);
            },
          ),
          _buildPillButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              ref.read(fileProvider.notifier).formatActiveFile();
              Fluttertoast.showToast(msg: 'Code formatted (mock)');
            },
          ),
          _buildPillButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).newFile();
              Fluttertoast.showToast(msg: 'New file created');
            },
          ),
          _buildPillButton(
            icon: Icons.download_rounded,
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final content = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
                Fluttertoast.showToast(msg: 'File imported');
              }
            },
          ),
          _buildPillButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: 'Code copied to clipboard');
              }
            },
          ),
          _buildPillButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                if (activeFile != null) {
                  ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content + data.text!);
                  Fluttertoast.showToast(msg: 'Pasted from clipboard');
                }
              }
            },
          ),
          _buildPillButton(
            icon: Icons.save_alt,
            label: 'Download',
            onTap: () async {
              if (activeFile != null) {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                Fluttertoast.showToast(msg: 'Saved to ${file.path}');
              }
            },
          ),
          _buildPillButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              if (activeFile != null) {
                final base64Code = base64Encode(utf8.encode(activeFile.content));
                Share.share('Check out my Dart code on DartMini: dartmini://code?c=$base64Code');
              }
            },
          ),
          _buildPillButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete File'),
                  content: const Text('Delete this file? This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                      onPressed: () {
                        ref.read(fileProvider.notifier).deleteActiveFile();
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: 'File deleted');
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildPillButton(
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


  void _showExamples(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examples'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: const Text('Hello World'), onTap: () => _loadExample(ctx, ref, 'Hello World', "void main() {\n  print('Hello World!');\n}")),
              ListTile(title: const Text('Input/Output'), onTap: () => _loadExample(ctx, ref, 'Input/Output', "import 'dart:io';\n\nvoid main() {\n  String? input = stdin.readLineSync();\n  print('You typed: \$input');\n}")),
              ListTile(title: const Text('List'), onTap: () => _loadExample(ctx, ref, 'List', "void main() {\n  List<int> numbers = [1, 2, 3];\n  for (var n in numbers) {\n    print(n);\n  }\n}")),
              ListTile(title: const Text('Class'), onTap: () => _loadExample(ctx, ref, 'Class', "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name');\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.greet();\n}")),
              ListTile(title: const Text('Async'), onTap: () => _loadExample(ctx, ref, 'Async', "Future<void> main() async {\n  print('Waiting...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}")),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _loadExample(BuildContext context, WidgetRef ref, String name, String code) {
    ref.read(fileProvider.notifier).importFile("${name.replaceAll(' ', '_').toLowerCase()}.dart", code);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: '$name loaded');
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: AppTheme.toolbarBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.toolbarBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.pureBlack, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.pureBlack,
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
