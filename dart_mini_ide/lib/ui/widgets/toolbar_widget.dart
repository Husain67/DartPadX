import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

import '../../core/theme/app_theme.dart';
import '../../logic/providers/files_provider.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.transparent, // Background handled by parent or theme
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildToolbarButton(
            context,
            icon: Icons.add,
            tooltip: 'New File',
            onTap: () => ref.read(filesProvider.notifier).createNewFile(),
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.file_upload,
            tooltip: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );

              if (result != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                ref.read(filesProvider.notifier).importFile(result.files.single.name, content);
                Fluttertoast.showToast(msg: "File imported");
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () async {
              final content = ref.read(filesProvider).activeFile?.content ?? '';
              await Clipboard.setData(ClipboardData(text: content));
              Fluttertoast.showToast(msg: "Code copied to clipboard");
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.paste,
            tooltip: 'Paste Code',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) {
                ref.read(filesProvider.notifier).updateActiveFileContent(data!.text!);
                Fluttertoast.showToast(msg: "Code pasted");
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onTap: () {
              final activeFile = ref.read(filesProvider).activeFile;
              if (activeFile != null) {
                 try {
                   // Newer dart_style requires languageVersion or defaults safely.
                   // Actually 3.0.0+ might require it. Let's check docs or try/catch or assume latest.
                   // The error says "Required named parameter 'languageVersion' must be provided."
                   // We'll provide DartFormatter.latestLanguageVersion if available or just a version.
                   // Actually, 'languageVersion' takes DartFormatter.latestLanguageVersion usually.
                   final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
                   final formatted = formatter.format(activeFile.content);
                   ref.read(filesProvider.notifier).updateActiveFileContent(formatted);
                   Fluttertoast.showToast(msg: "Code formatted");
                 } catch (e) {
                   Fluttertoast.showToast(msg: "Format Error: \${e.toString().split('\n').first}");
                 }
              }
            },
          ),
          const SizedBox(width: 8),
           _buildToolbarButton(
            context,
            icon: Icons.lightbulb_outline,
            tooltip: 'Examples',
            onTap: () {
              _showExamplesDialog(context, ref);
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.download,
            tooltip: 'Download .dart',
            onTap: () async {
              final activeFile = ref.read(filesProvider).activeFile;
              if (activeFile != null) {
                final tempDir = await getTemporaryDirectory();
                final file = File('\${tempDir.path}/\${activeFile.name}');
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Download \${activeFile.name}');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.share,
            tooltip: 'Share Code',
            onTap: () {
              final content = ref.read(filesProvider).activeFile?.content ?? '';
              Share.share(content);
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.delete,
            tooltip: 'Delete File',
            onTap: () {
              final activeFile = ref.read(filesProvider).activeFile;
              if (activeFile == null) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete this file?"),
                  content: const Text("This cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        ref.read(filesProvider.notifier).deleteActiveFile();
                        Navigator.pop(context);
                        Fluttertoast.showToast(msg: "File deleted");
                      },
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            context,
            icon: Icons.settings,
            tooltip: 'Settings',
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

  Widget _buildToolbarButton(BuildContext context, {required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.toolbarButtonBg,
        borderRadius: BorderRadius.circular(24), // Pill shape (circle for square aspect)
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 24),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'Input/Output': 'import "dart:io";\n\nvoid main() {\n  print("Enter name:");\n  // String? name = stdin.readLineSync();\n  // print("Hello \$name");\n  print("Standard Input not supported in all compilers via API");\n}',
      'List': 'void main() {\n  var list = [1, 2, 3];\n  list.add(4);\n  print(list);\n}',
      'Class': 'class Person {\n  String name;\n  Person(this.name);\n  void sayHello() => print("Hello \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.sayHello();\n}',
      'Async': 'Future<void> main() async {\n  print("Start");\n  await Future.delayed(Duration(seconds: 1));\n  print("End");\n}',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Examples'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              onTap: () {
                 ref.read(filesProvider.notifier).createNewFile();
                 // A slight delay to ensure new file is active before updating content
                 Future.delayed(const Duration(milliseconds: 100), () {
                    ref.read(filesProvider.notifier).updateActiveFileContent(e.value);
                    Navigator.pop(context);
                 });
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }
}
