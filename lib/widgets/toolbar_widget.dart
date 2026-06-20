
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFile = ref.watch(fileProvider.notifier).currentFile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () async {
              await ref.read(fileProvider.notifier).createFile();
              Fluttertoast.showToast(msg: 'New file created');
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.file_download,
            label: 'Import',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );

              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String contents = await file.readAsString();
                await ref.read(fileProvider.notifier).createFile(result.files.single.name);
                ref.read(fileProvider.notifier).updateCurrentFileContent(contents);
                Fluttertoast.showToast(msg: 'File imported successfully');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () async {
              if (currentFile != null) {
                await Clipboard.setData(ClipboardData(text: currentFile.content));
                Fluttertoast.showToast(msg: 'Code copied to clipboard');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null && currentFile != null) {
                final newContent = currentFile.content + data.text!;
                ref.read(fileProvider.notifier).updateCurrentFileContent(newContent);
                Fluttertoast.showToast(msg: 'Pasted successfully');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () async {
              if (currentFile != null) {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final file = File('${directory.path}/${currentFile.name}');
                  await file.writeAsString(currentFile.content);
                  Fluttertoast.showToast(msg: 'Saved to ${file.path}');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to download: $e');
                }
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              if (currentFile != null) {
                Share.share(currentFile.content, subject: 'Check out my Dart code!');
              }
            },
          ),
          const SizedBox(width: 8),
          _buildToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            color: Colors.red,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete File'),
                    content: const Text('Delete this file? This cannot be undone.'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteCurrentFile();
                          Navigator.of(context).pop();
                          Fluttertoast.showToast(msg: 'File deleted');
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.buttonCream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color ?? Colors.black87),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
