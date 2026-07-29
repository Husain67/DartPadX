import '../screens/settings_screen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

import '../providers/file_provider.dart';
import '../models/editor_file.dart';


class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  Widget _buildIconButton(IconData icon, VoidCallback onPressed, String tooltip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final fileNotifier = ref.read(fileProvider.notifier);
    final activeFile = fileState.activeFile;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildIconButton(Icons.format_align_left, () {

             if (activeFile != null) {
                try { fileNotifier.updateActiveFileContent(DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(activeFile.content)); Fluttertoast.showToast(msg: "Formatted Code"); } catch (e) { Fluttertoast.showToast(msg: "Syntax error"); }
             }
          }, "Format Code"),
          _buildIconButton(Icons.book, () {
             final code = '''void main() {\n  print('Hello from Example');\n}''';
             fileNotifier.addFile(EditorFile(name: 'example.dart', content: code));
             Fluttertoast.showToast(msg: "Loaded Example");
          }, "Examples"),
          _buildIconButton(Icons.clear_all, () {
             Fluttertoast.showToast(msg: "Output cleared (Restart Run)");
          }, "Clear Output"),
          _buildIconButton(Icons.add, () {
            fileNotifier.addFile(EditorFile(name: 'untitled.dart'));
            Fluttertoast.showToast(msg: "New file created");
          }, "New File"),
          _buildIconButton(Icons.download_for_offline, () async {
            try {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
                withData: true,
              );
              if (result != null && result.files.single.bytes != null) {
                final content = utf8.decode(result.files.single.bytes!);
                final name = result.files.single.name;
                fileNotifier.importFile(name, content);
                Fluttertoast.showToast(msg: "Imported \$name");
              }
            } catch (e) {
              Fluttertoast.showToast(msg: "Error importing file");
            }
          }, "Import File"),
          _buildIconButton(Icons.copy, () {
            if (activeFile != null) {
              Clipboard.setData(ClipboardData(text: activeFile.content));
              Fluttertoast.showToast(msg: "Code copied to clipboard");
            }
          }, "Copy Code"),
          _buildIconButton(Icons.paste, () async {
            if (activeFile != null) {
              final data = await Clipboard.getData('text/plain');
              if (data != null && data.text != null) {
                fileNotifier.updateActiveFileContent(activeFile.content + data.text!);
                Fluttertoast.showToast(msg: "Pasted from clipboard");
              }
            }
          }, "Paste Code"),
          _buildIconButton(Icons.file_download, () async {
            if (activeFile != null) {
              try {
                Directory? dir;
                if (Platform.isAndroid) {
                  dir = await getExternalStorageDirectory();
                } else if (Platform.isIOS) {
                  dir = await getApplicationDocumentsDirectory();
                }
                if (dir != null) {
                  final file = File('\${dir.path}/\${activeFile.name}');
                  await file.writeAsString(activeFile.content);
                  Fluttertoast.showToast(msg: "Saved to \${file.path}");
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Error downloading file");
              }
            }
          }, "Download .dart"),
          _buildIconButton(Icons.share, () {
            if (activeFile != null) {
              Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
            }
          }, "Share"),
          _buildIconButton(Icons.delete, () {
            if (activeFile != null) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete this file?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        fileNotifier.deleteFile(activeFile.id);
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: "File deleted");
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            }
          }, "Delete File"),
          _buildIconButton(Icons.settings, () {
             Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SettingsScreen()));
          }, "Settings"),
        ],
      ),
    );
  }
}
