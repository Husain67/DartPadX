import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_style/dart_style.dart';

import '../models/code_file.dart';
import '../providers/execution_provider.dart';
import '../providers/file_provider.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                    color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isExecuting
                  ? null
                  : () {
                      final activeFile = fileState.activeFile;
                      if (activeFile != null) {
                        ref.read(executionProvider.notifier).executeCode(activeFile.content);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: execState.isExecuting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.play_arrow, size: 18),
              label: Text(execState.isExecuting ? 'Running' : 'Run'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildToolbar(context, ref, fileState),
              const Expanded(
                child: EditorWidget(),
              ),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'List & Loops': 'void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var item in list) {\n    print(item * 2);\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.greet();\n}',
      'Async/Await': 'Future<void> fetch() async {\n  await Future.delayed(Duration(seconds: 1));\n  print("Data fetched");\n}\n\nvoid main() async {\n  print("Fetching...");\n  await fetch();\n}'
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          ...examples.entries.map((e) => ListTile(
            title: Text(e.key, style: const TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.add, color: Color(0xFFFACC15)),
            onTap: () {
               final newFile = CodeFile(
                  id: const Uuid().v4(),
                  name: '${e.key.replaceAll(' ', '_').toLowerCase()}.dart',
                  content: e.value,
               );
               ref.read(fileProvider.notifier).addFile(newFile);
               Navigator.pop(ctx);
               Fluttertoast.showToast(msg: "Example loaded");
            },
          )),
        ],
      )
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref, FileState fileState) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.add,
              label: 'New File',
              onTap: () {
                ref.read(fileProvider.notifier).createNewFile();
                Fluttertoast.showToast(msg: "New file created");
              },
            ),
            _ToolbarButton(
              icon: Icons.download_rounded,
              label: 'Import',
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['dart', 'txt'],
                );

                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  final content = await file.readAsString();
                  final newFile = CodeFile(
                    id: const Uuid().v4(),
                    name: result.files.single.name,
                    content: content,
                  );
                  ref.read(fileProvider.notifier).addFile(newFile);
                  Fluttertoast.showToast(msg: "File imported");
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                final content = fileState.activeFile?.content ?? '';
                Clipboard.setData(ClipboardData(text: content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              },
            ),
            _ToolbarButton(
              icon: Icons.paste,
              label: 'Paste',
              onTap: () async {
                final data = await Clipboard.getData('text/plain');
                if (data != null && data.text != null) {
                  final currentContent = fileState.activeFile?.content ?? '';
                  ref.read(fileProvider.notifier).updateActiveFileContent(currentContent + data.text!);
                  Fluttertoast.showToast(msg: "Pasted from clipboard");
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.format_align_left,
              label: 'Format Code',
              onTap: () {
                final activeFile = fileState.activeFile;
                if (activeFile != null) {
                   try {
                     final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                     final formattedCode = formatter.format(activeFile.content);
                     ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
                     Fluttertoast.showToast(msg: "Code formatted");
                   } catch (e) {
                     Fluttertoast.showToast(msg: "Syntax error: Cannot format");
                   }
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.collections_bookmark,
              label: 'Examples',
              onTap: () {
                 _showExamplesGallery(context, ref);
              },
            ),
            _ToolbarButton(
              icon: Icons.file_download,
              label: 'Download',
              onTap: () async {
                final activeFile = fileState.activeFile;
                if (activeFile != null) {
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/${activeFile.name}');
                  await file.writeAsString(activeFile.content);
                  await Share.shareXFiles([XFile(file.path)]);
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () {
                final activeFile = fileState.activeFile;
                if (activeFile != null) {
                   final base64Code = base64Encode(utf8.encode(activeFile.content));
                   Clipboard.setData(ClipboardData(text: 'dartmini://share?code=$base64Code'));
                   Fluttertoast.showToast(msg: "Mock Deep-link copied");
                }
              },
            ),
            _ToolbarButton(
              icon: Icons.delete_outline,
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
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteActiveFile();
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
            _ToolbarButton(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
