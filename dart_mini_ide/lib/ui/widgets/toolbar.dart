import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../../models/code_file.dart';
import '../screens/settings_screen.dart';
import 'custom_buttons.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            PillButton(
              icon: Icons.add_rounded,
              label: 'New',
              onTap: () {
                ref.read(fileProvider.notifier).addFile();
                Fluttertoast.showToast(msg: "New file created");
              },
            ),
            PillButton(
              icon: Icons.file_upload_rounded,
              label: 'Import',
              onTap: () => ref.read(fileProvider.notifier).importFile(),
            ),
            PillButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Format',
              onTap: () {
                if (fileState.currentFile != null) {
                  try {
                    final formatter = DartFormatter();
                    final formatted = formatter.format(fileState.currentFile!.content);
                    ref.read(fileProvider.notifier).updateContent(formatted);
                    Fluttertoast.showToast(msg: "Code formatted");
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Format error: Check syntax");
                  }
                }
              },
            ),
             PillButton(
              icon: Icons.library_books_rounded,
              label: 'Examples',
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (ctx) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Examples Gallery',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Hello World', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          ref.read(fileProvider.notifier).addFile();
                          ref.read(fileProvider.notifier).updateContent('void main() {\n  print("Hello, World!");\n}');
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: const Text('Input/Output', style: TextStyle(color: Colors.white)),
                        onTap: () {
                           ref.read(fileProvider.notifier).addFile();
                           ref.read(fileProvider.notifier).updateContent('import "dart:io";\n\nvoid main() {\n  stdout.write("Enter name: ");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}');
                           Navigator.pop(ctx);
                        },
                      ),
                       ListTile(
                        title: const Text('Async/Await', style: TextStyle(color: Colors.white)),
                        onTap: () {
                           ref.read(fileProvider.notifier).addFile();
                           ref.read(fileProvider.notifier).updateContent('Future<void> main() async {\n  print("Fetching data...");\n  await Future.delayed(Duration(seconds: 2));\n  print("Data received!");\n}');
                           Navigator.pop(ctx);
                        },
                      ),
                       ListTile(
                        title: const Text('Classes', style: TextStyle(color: Colors.white)),
                        onTap: () {
                           ref.read(fileProvider.notifier).addFile();
                           ref.read(fileProvider.notifier).updateContent('class Person {\n  String name;\n  Person(this.name);\n  void sayHello() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.sayHello();\n}');
                           Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            PillButton(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () {
                if (fileState.currentFile != null) {
                  Clipboard.setData(ClipboardData(text: fileState.currentFile!.content));
                  Fluttertoast.showToast(msg: "Code copied to clipboard");
                }
              },
            ),
            PillButton(
              icon: Icons.paste_rounded,
              label: 'Paste',
              onTap: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                  // This updates the entire content.
                  // Ideally insert at cursor, but we don't have access to cursor here easily
                  // unless we lift controller state up or expose it via provider.
                  // For "Paste" button on toolbar, replacing or appending is common if cursor unknown.
                  // But users expect paste at cursor.
                  // Since we cannot easily get cursor without complex state lifting,
                  // we will Append or Replace?
                  // Let's Replace for now or Append?
                  // "Paste" usually implies "Paste at cursor".
                  // If we can't do that, maybe Append?
                  // Let's Append to be safe, or show dialog?
                  // Actually, let's just REPLACE for simplicity in this "beta", or
                  // try to get current selection if we can.
                  // But we can't.
                  // Let's Append.
                  // Wait, "Paste" button in toolbar usually replaces selection or inserts at cursor.
                  // Without cursor, it's ambiguous.
                  // I'll implement "Replace All" behavior but maybe warn?
                  // Or just Append.

                  // Let's just update content with pasted text? No that overwrites.
                  // Let's Append.
                  final currentContent = fileState.currentFile?.content ?? '';
                  ref.read(fileProvider.notifier).updateContent(currentContent + '\n' + data.text!);
                  Fluttertoast.showToast(msg: "Pasted at end of file");
                }
              },
            ),
            PillButton(
              icon: Icons.download_rounded,
              label: 'Download',
              onTap: () => ref.read(fileProvider.notifier).downloadCurrentFile(),
            ),
            PillButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: () {
                 if (fileState.currentFile != null) {
                   Share.share(fileState.currentFile!.content);
                 }
              },
            ),
            PillButton(
              icon: Icons.delete_rounded,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'This cannot be undone. Are you sure?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteCurrentFile();
                          Navigator.pop(ctx);
                          Fluttertoast.showToast(msg: "File deleted");
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            PillButton(
              icon: Icons.settings_rounded,
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
      ),
    );
  }
}
