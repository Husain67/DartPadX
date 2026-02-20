import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'custom_button.dart';
import '../../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(activeFileProvider);

    return Container(
      height: 60,
      color: Colors.transparent,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          CustomToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
               ref.read(fileListProvider.notifier).createNewFile();
            },
          ),
          CustomToolbarButton(
            icon: Icons.file_upload_outlined,
            label: 'Import',
            onTap: () async {
               try {
                 FilePickerResult? result = await FilePicker.platform.pickFiles(
                   type: FileType.custom,
                   allowedExtensions: ['dart'],
                   withData: true,
                 );
                 if (result != null) {
                   final file = result.files.single;
                   // Use bytes because path might not be accessible on mobile securely or scoped storage
                   final content = utf8.decode(file.bytes!);
                   ref.read(fileListProvider.notifier).createNewFile(
                     name: file.name,
                     content: content,
                   );
                   Fluttertoast.showToast(msg: "Imported ${file.name}");
                 }
               } catch (e) {
                 Fluttertoast.showToast(msg: "Import failed: $e");
               }
            },
          ),
          CustomToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          CustomToolbarButton(
             icon: Icons.paste,
             label: 'Paste',
             onTap: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null && activeFile != null) {
                   ref.read(fileListProvider.notifier).updateFileContent(activeFile.id, activeFile.content + (data!.text ?? ''));
                   Fluttertoast.showToast(msg: "Pasted");
                }
             },
          ),
          CustomToolbarButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () {
               if (activeFile != null) {
                 Share.share(activeFile.content, subject: activeFile.name);
               }
            },
          ),
          CustomToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
               if (activeFile != null) {
                 Share.share(activeFile.content);
               }
            },
          ),
          CustomToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
            onTap: () {
              if (activeFile != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete File?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                           ref.read(fileListProvider.notifier).deleteFile(activeFile.id);
                           Navigator.pop(ctx);
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
           CustomToolbarButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => const SettingsScreen())
               );
            },
          ),
        ],
      ),
    );
  }
}
