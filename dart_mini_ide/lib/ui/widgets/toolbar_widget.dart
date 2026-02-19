import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';
import '../../providers/file_provider.dart';
import '../../utils/constants.dart';
import '../settings_screen.dart';
import 'examples_dialog.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          _buildButton(context, ref, Icons.add, "New", _newFile),
          _buildButton(context, ref, Icons.file_open, "Import", _importFile),
          _buildButton(context, ref, Icons.copy, "Copy", _copyCode),
          _buildButton(context, ref, Icons.paste, "Paste", _pasteCode),
          _buildButton(context, ref, Icons.format_paint, "Format", _formatCode),
          _buildButton(context, ref, Icons.library_books, "Examples", _showExamples),
          _buildButton(context, ref, Icons.share, "Share", _shareFile), // Use Share for download/export
          _buildButton(context, ref, Icons.delete, "Delete", _deleteFile, isDestructive: true),
          _buildButton(context, ref, Icons.settings, "Settings", _openSettings),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, WidgetRef ref, IconData icon, String label, Function(BuildContext, WidgetRef) onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 48,
          height: 48,
          child: ElevatedButton(
            onPressed: () => onTap(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.toolbarButtonBg,
              foregroundColor: isDestructive ? AppColors.error : Colors.black,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.toolbarButtonBorder, width: 1),
              ),
              elevation: 0,
            ),
            child: Icon(icon, size: 24),
          ),
        ),
      ),
    );
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    String filename = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            onChanged: (v) => filename = v,
            decoration: const InputDecoration(hintText: 'filename.dart', filled: true),
            autofocus: true,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (filename.isNotEmpty) {
                  ref.read(fileProvider.notifier).addFile(filename);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      }
    );
  }

  Future<void> _importFile(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
         type: FileType.any, // Use any to allow selecting dart files if custom extension fails on some devices
         // allowedExtensions: ['dart'],
      );
      if (result != null) {
         final file = File(result.files.single.path!);
         final content = await file.readAsString();
         ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing: $e')));
      }
    }
  }

  void _copyCode(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _pasteCode(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
       ref.read(fileProvider.notifier).updateFileContent(data!.text!);
    }
  }

  void _formatCode(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateFileContent(formatted);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format Error: $e')));
      }
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const ExamplesDialog());
  }

  void _shareFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: activeFile.name);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final index = ref.read(fileProvider).activeIndex;
              ref.read(fileProvider.notifier).deleteFile(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}
