import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'editor_screen.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: tc,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'filename.dart',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (tc.text.isNotEmpty) {
                ref.read(fileProvider.notifier).createFile(tc.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String fileId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(fileId);
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "File deleted",
                backgroundColor: Colors.grey[900],
                textColor: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello, World!');\n}",
      'List Example': "void main() {\n  var list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}",
      'Class Example': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name');\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.greet();\n}",
      'Async Example': "Future<void> main() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}"
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Examples', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key, style: const TextStyle(color: Colors.white)),
              onTap: () {
                ref.read(fileProvider.notifier).createFile('${e.key.replaceAll(" ", "_")}.dart', content: e.value);
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(fileProvider.notifier).activeFile;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: () {
                if (activeFile != null) {
                  ref.read(executionProvider.notifier).executeCode(activeFile.content);
                }
              },
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Toolbar
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    children: [
                      _ToolbarBtn(icon: Icons.add, label: 'New', onTap: () => _showNewFileDialog(context, ref)),
                      _ToolbarBtn(icon: Icons.download, label: 'Import', onTap: () async {
                         final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['dart', 'txt']);
                         if (result != null && result.files.single.path != null) {
                           final file = File(result.files.single.path!);
                           final content = await file.readAsString();
                           ref.read(fileProvider.notifier).createFile(result.files.single.name, content: content);
                         }
                      }),
                      _ToolbarBtn(icon: Icons.copy, label: 'Copy', onTap: () {
                         if (activeFile != null) {
                           Clipboard.setData(ClipboardData(text: activeFile.content));
                           Fluttertoast.showToast(msg: "Copied to clipboard", backgroundColor: Colors.grey[900]);
                         }
                      }),
                      _ToolbarBtn(icon: Icons.paste, label: 'Paste', onTap: () async {
                         final data = await Clipboard.getData(Clipboard.kTextPlain);
                         if (data != null && data.text != null && activeFile != null) {
                            final newContent = activeFile.content + data.text!;
                            ref.read(fileProvider.notifier).updateContent(newContent);
                         }
                      }),
                      _ToolbarBtn(icon: Icons.file_download, label: 'Download', onTap: () async {
                         if (activeFile != null) {
                           final dir = await getTemporaryDirectory();
                           final file = File('${dir.path}/${activeFile.name}');
                           await file.writeAsString(activeFile.content);
                           await Share.shareXFiles([XFile(file.path)], text: 'Exported from DartMini IDE');
                         }
                      }),
                      _ToolbarBtn(icon: Icons.share, label: 'Share', onTap: () {
                         if (activeFile != null) {
                            final b64 = base64Encode(utf8.encode(activeFile.content));
                            Share.share('Check out my Dart code!\n\ndartmini://code?data=$b64');
                         }
                      }),
                      _ToolbarBtn(icon: Icons.format_align_left, label: 'Format', onTap: () {
                         if (activeFile != null) {
                           try {
                             final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                             final formatted = formatter.format(activeFile.content);
                             ref.read(fileProvider.notifier).updateContent(formatted);
                             Fluttertoast.showToast(msg: "Formatted", backgroundColor: Colors.grey[900]);
                           } catch (e) {
                             Fluttertoast.showToast(msg: "Syntax error: Cannot format", backgroundColor: Colors.redAccent);
                           }
                         }
                      }),
                      _ToolbarBtn(icon: Icons.lightbulb, label: 'Examples', onTap: () => _showExamples(context, ref)),
                      _ToolbarBtn(icon: Icons.delete, label: 'Delete', onTap: () {
                         if (activeFile != null) {
                           _showDeleteConfirmation(context, ref, activeFile.id);
                         }
                      }),
                      _ToolbarBtn(icon: Icons.settings, label: 'Settings', onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      }),
                    ],
                  ),
                ),
                // Editor
                const Expanded(
                  child: EditorScreen(),
                ),
                // space for bottom sheet
                const SizedBox(height: 60),
              ],
            ),
            // Bottom Sheet for output
            const OutputSheet(),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.black87),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
