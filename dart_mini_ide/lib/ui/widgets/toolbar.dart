import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/file_provider.dart';
import '../../utils/theme.dart';
import '../../utils/format_utils.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPillButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.lightbulb_outline,
            label: 'Examples',
            onTap: () {
              _showExamplesGallery(context, ref);
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.download_for_offline,
            label: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final content = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final formatted = FormatUtils.formatDartCode(activeFile.content);
                ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                Fluttertoast.showToast(msg: "Code formatted");
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  final newContent = activeFile.content + '\n' + data.text!;
                  ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
                } else {
                  ref.read(fileProvider.notifier).importFile('pasted.dart', data.text!);
                }
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final dir = await getTemporaryDirectory();
                final path = '${dir.path}/${activeFile.name}';
                final file = File(path);
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(path)], text: 'Exported from DartMini IDE');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final encoded = base64Encode(utf8.encode(activeFile.content));
                final link = 'dartmini://share?code=$encoded';
                Clipboard.setData(ClipboardData(text: link));
                Fluttertoast.showToast(msg: "Deep-link copied to clipboard!");
              }
            },
          ),
          const SizedBox(width: 8),
          _buildPillButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile == null) return;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.bgColorEnd,
                  title: const Text('Delete this file?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                )
              );

              if (confirm == true) {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Fluttertoast.showToast(msg: "File deleted");
              }
            },
          ),
          const SizedBox(width: 8),
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

  Widget _buildPillButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print(\'Hello World!\');\n}',
      'Input/Output': 'import \'dart:io\';\n\nvoid main() {\n  stdout.write(\'Enter your name: \');\n  String? name = stdin.readLineSync();\n  print(\'Hello, \$name!\');\n}',
      'List': 'void main() {\n  List<String> fruits = [\'Apple\', \'Banana\', \'Mango\'];\n  for (var fruit in fruits) {\n    print(fruit);\n  }\n}',
      'Class': 'class Person {\n  String name;\n  int age;\n  Person(this.name, this.age);\n  void introduce() {\n    print(\'Hi, I am \$name, \$age years old.\');\n  }\n}\n\nvoid main() {\n  var p = Person(\'Alice\', 30);\n  p.introduce();\n}',
      'Async': 'Future<void> main() async {\n  print(\'Fetching data...\');\n  await Future.delayed(Duration(seconds: 2));\n  print(\'Data fetched successfully!\');\n}',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgColorEnd,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...examples.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(fileProvider.notifier).importFile('${e.key.toLowerCase().replaceAll('/', '_')}.dart', e.value);
              },
            )),
          ],
        );
      },
    );
  }
}
