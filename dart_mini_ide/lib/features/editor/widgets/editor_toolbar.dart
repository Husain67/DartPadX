import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/shared/widgets/pill_button.dart';
import 'package:dart_mini_ide/features/editor/providers/editor_provider.dart';
import 'package:dart_mini_ide/features/settings/screens/settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dart_style/dart_style.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          PillButton(
            icon: Icons.add,
            tooltip: 'New File',
            onTap: () => notifier.createNewFile(),
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.file_upload,
            tooltip: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );
              if (result != null) {
                 final platformFile = result.files.first;
                 String content = '';
                 try {
                   if (platformFile.bytes != null) {
                     content = utf8.decode(platformFile.bytes!);
                   } else if (platformFile.path != null) {
                     content = await File(platformFile.path!).readAsString();
                   }
                   notifier.importFile(platformFile.name, content);
                   Fluttertoast.showToast(msg: "Imported ${platformFile.name}");
                 } catch (e) {
                   Fluttertoast.showToast(msg: "Error importing file: $e");
                 }
              }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onTap: () {
               if (editorState.activeFile != null) {
                  try {
                    final formatter = DartFormatter();
                    final formatted = formatter.format(editorState.activeFile!.content);
                    notifier.updateFileContent(editorState.activeFile!.id, formatted);
                    Fluttertoast.showToast(msg: "Formatted");
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Format Error: $e");
                  }
               }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () {
              if (editorState.activeFile != null) {
                Clipboard.setData(ClipboardData(text: editorState.activeFile!.content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.paste,
            tooltip: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null && editorState.activeFileId != null) {
                 notifier.updateFileContent(editorState.activeFileId!, data!.text!);
                 Fluttertoast.showToast(msg: "Pasted");
              }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.download,
            tooltip: 'Download .dart',
            onTap: () async {
               if (editorState.activeFile != null) {
                  try {
                    final directory = await getTemporaryDirectory();
                    final file = File('${directory.path}/${editorState.activeFile!.name}');
                    await file.writeAsString(editorState.activeFile!.content);

                    await Share.shareXFiles([XFile(file.path)], text: 'Download ${editorState.activeFile!.name}');
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Error preparing download: $e");
                  }
               }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.share,
            tooltip: 'Share',
            onTap: () {
              if (editorState.activeFile != null) {
                Share.share(editorState.activeFile!.content);
              }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.delete,
            tooltip: 'Delete File',
            isDestructive: true,
            onTap: () {
               if (editorState.activeFile != null) {
                 showDialog(
                   context: context,
                   builder: (c) => AlertDialog(
                     title: const Text('Delete File?'),
                     content: const Text('This cannot be undone.'),
                     actions: [
                       TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                       TextButton(
                         onPressed: () {
                           notifier.deleteFile(editorState.activeFile!.id);
                           Navigator.pop(c);
                           Fluttertoast.showToast(msg: "File deleted");
                         },
                         child: const Text('Delete', style: TextStyle(color: Colors.red)),
                       ),
                     ],
                   ),
                 );
               }
            },
          ),
          const SizedBox(width: 8),
          PillButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
