import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../providers/file_provider.dart';
import '../screens/settings_screen.dart';
import 'package:dart_style/dart_style.dart';
import '../utils/examples.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  Widget _buildButton(BuildContext context, IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(fileProvider).activeFileId != null
        ? ref.watch(fileProvider.notifier).activeFile
        : null;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildButton(context, Icons.note_add, 'New File', () {
               _showNewFileDialog(context, ref);
            }),
            _buildButton(context, Icons.book, 'Examples', () {
               _showExamplesDialog(context, ref);
            }),
            _buildButton(context, Icons.file_download, 'Import .dart', () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['dart', 'txt'],
                  withData: true,
                );

                if (result != null && result.files.single.bytes != null) {
                  final content = utf8.decode(result.files.single.bytes!);
                  ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
                  Fluttertoast.showToast(msg: "File imported");
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Error importing file");
              }
            }),
            _buildButton(context, Icons.format_align_left, 'Format Code', () {
               if (activeFile != null) {
                 try {
                    final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
                    final formattedCode = formatter.format(activeFile.content);
                    ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
                    Fluttertoast.showToast(msg: "Code formatted");
                 } catch (e) {
                    Fluttertoast.showToast(msg: "Syntax error: could not format");
                 }
               }
            }),
            _buildButton(context, Icons.copy, 'Copy code', () {
               if (activeFile != null) {
                 Clipboard.setData(ClipboardData(text: activeFile.content));
                 Fluttertoast.showToast(msg: "Code copied to clipboard");
               }
            }),
            _buildButton(context, Icons.paste, 'Paste', () async {
               if (activeFile != null) {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null && data.text != null) {
                    ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
                    Fluttertoast.showToast(msg: "Pasted from clipboard");
                  }
               }
            }),
            _buildButton(context, Icons.download, 'Download .dart', () async {
               if (activeFile != null) {
                 try {
                   Directory? dir;
                   if (Platform.isAndroid) {
                     dir = await getExternalStorageDirectory();
                   } else {
                     dir = await getApplicationDocumentsDirectory();
                   }

                   if (dir != null) {
                      final file = File('\${dir.path}/\${activeFile.name}');
                      await file.writeAsString(activeFile.content);
                      Fluttertoast.showToast(msg: "Saved to \${file.path}");
                   }
                 } catch(e) {
                    Fluttertoast.showToast(msg: "Error saving file");
                 }
               }
            }),
            _buildButton(context, Icons.share, 'Share', () {
                if (activeFile != null) {
                  Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
                }
            }),
            _buildButton(context, Icons.delete, 'Delete current file', () {
               if (activeFile != null) {
                 _showDeleteDialog(context, ref, activeFile.id);
               }
            }),
            _buildButton(context, Icons.settings, 'Settings', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    String fileName = 'new_file.dart';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'File Name'),
            onChanged: (val) => fileName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
              onPressed: () {
                if (!fileName.endsWith('.dart')) fileName += '.dart';
                ref.read(fileProvider.notifier).createNewFile(fileName);
                Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      }
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Examples'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: IDEExamples.gallery.length,
              itemBuilder: (context, index) {
                final key = IDEExamples.gallery.keys.elementAt(index);
                final value = IDEExamples.gallery.values.elementAt(index);
                return ListTile(
                   title: Text(key),
                   trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                   onTap: () {
                     ref.read(fileProvider.notifier).importFile('${key.replaceAll(" ", "_").toLowerCase()}.dart', value);
                     Navigator.pop(context);
                     Fluttertoast.showToast(msg: "Loaded \$key");
                   }
                );
              }
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      }
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: const Text('Delete this file? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(id);
                Fluttertoast.showToast(msg: "File deleted");
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }
}
