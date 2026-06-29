import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../../providers/file_provider.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  final CodeController codeController;

  const EditorToolbar({super.key, required this.codeController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolButton(
            icon: Icons.add_box,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildToolButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () => _handleImport(context, ref),
          ),
          _buildToolButton(
            icon: Icons.save_alt,
            label: 'Download .dart',
            onTap: () => _handleDownload(context, ref),
          ),
          _buildToolButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _handleCopy(),
          ),
          _buildToolButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(),
          ),
          _buildToolButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(ref),
          ),
          _buildToolButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
          ),
          _buildToolButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => _navigateToSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    TextEditingController nameController = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter file name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(fileProvider.notifier).createFile(name);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        final name = file.name;
        String content = '';
        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        }
        ref.read(fileProvider.notifier).createFile(name, content: content);
        Fluttertoast.showToast(msg: "Imported $name", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    try {
      // In a real mobile app, this would use saf (Storage Access Framework) on Android
      // or similar to let the user pick a location. For simplicity we write to Documents.
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final filePath = '${directory.path}/${activeFile.name}';
        final file = File(filePath);
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to $filePath", backgroundColor: Colors.green);
      } else {
        Fluttertoast.showToast(msg: "Failed to get directory", backgroundColor: Colors.red);
      }
    } catch (e) {
       Fluttertoast.showToast(msg: "Download failed: $e", backgroundColor: Colors.red);
    }
  }

  void _handleCopy() {
    final selection = codeController.selection;
    final text = codeController.text;

    String textToCopy = '';
    if (selection.isValid && !selection.isCollapsed) {
      textToCopy = selection.textInside(text);
    } else {
      textToCopy = text;
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      Fluttertoast.showToast(msg: "Code copied to clipboard", backgroundColor: Colors.green);
    }
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final text = codeController.text;
      final selection = codeController.selection;

      int start = selection.isValid ? selection.start : text.length;
      int end = selection.isValid ? selection.end : text.length;

      // Ensure offsets are within bounds
      start = start.clamp(0, text.length);
      end = end.clamp(0, text.length);

      final newText = text.replaceRange(start, end, data.text!);

      // Update the code controller directly. The listener will sync it to Riverpod state.
      codeController.text = newText;
      codeController.selection = TextSelection.collapsed(offset: start + data.text!.length);

      Fluttertoast.showToast(msg: "Pasted code", backgroundColor: Colors.green);
    }
  }

  void _handleShare(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Shared from DartMini IDE');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFileId = ref.read(fileProvider).activeFileId;
    if (activeFileId != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete File'),
            content: const Text('Delete this file? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(fileProvider.notifier).deleteFile(activeFileId);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: "File deleted", backgroundColor: Colors.red);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}
