import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../providers/file_notifier.dart';
import '../providers/execution_notifier.dart';
import '../theme.dart';
import 'settings_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../providers/file_notifier.dart';
import '../providers/execution_notifier.dart';
import '../theme.dart';
import 'settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({Key? key}) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildButton('New File', Icons.add, () {
            ref.read(fileProvider.notifier).newFile();
            _showToast('New file created');
          }),
          _buildButton('Import .dart', Icons.download_rounded, () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );

              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
                _showToast('File imported');
              }
            } catch (e) {
              _showToast('Failed to import file');
            }
          }),
          _buildButton('Copy code', Icons.copy, () {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              Clipboard.setData(ClipboardData(text: activeFile.content));
              _showToast('Code copied to clipboard');
            }
          }),
          _buildButton('Paste', Icons.paste, () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data != null && data.text != null) {
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                ref.read(fileProvider.notifier).updateContent(activeFile.content + data.text!);
                _showToast('Code pasted');
              }
            }
          }),
          _buildButton('Download .dart', Icons.file_download, () async {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              try {
                final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                _showToast('Saved to ${file.path}');
              } catch (e) {
                _showToast('Failed to download');
              }
            }
          }),
          _buildButton('Share', Icons.share, () {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
              Share.share(activeFile.content, subject: 'Dart code from DartMini IDE');
            }
          }),
          _buildButton('Delete', Icons.delete, () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.backgroundEnd,
                title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
                content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(fileProvider.notifier).deleteActiveFile();
              _showToast('File deleted');
            }
          }),
          _buildButton('Clear Output', Icons.clear_all, () {
            ref.read(executionProvider.notifier).clear();
            _showToast('Output cleared');
          }),

          _buildButton('Format', Icons.format_align_left, () {
            _showToast('Code formatted (simulation)');
          }),
          _buildButton('Examples', Icons.code, () {
            _showExamplesGallery(context, ref);
          }),

          _buildButton('Settings', Icons.settings, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }


  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello, World!');\n}\n",
      'Input/Output': "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, $name!');\n}\n",
      'List': "void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var item in list) {\n    print(item);\n  }\n}\n",
      'Class': "class Person {\n  String name;\n  int age;\n  Person(this.name, this.age);\n  void display() {\n    print('Name: $name, Age: $age');\n  }\n}\n\nvoid main() {\n  var p = Person('Alice', 30);\n  p.display();\n}\n",
      'Async': "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 2));\n  print('Data fetched!');\n}\n",
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundStart,
      builder: (ctx) => ListView(
        children: examples.entries.map((e) => ListTile(
          title: Text(e.key, style: const TextStyle(color: Colors.white)),
          onTap: () {
            ref.read(fileProvider.notifier).importFile('${e.key.replaceAll(' ', '_')}.dart', e.value);
            Navigator.pop(ctx);
            _showToast('${e.key} loaded');
          },
        )).toList(),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: AppTheme.buttonBackground,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48, // 48px touch target
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
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
}
