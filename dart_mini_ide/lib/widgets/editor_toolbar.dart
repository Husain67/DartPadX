import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../core/theme.dart';
import '../providers/file_provider.dart';
import '../screens/settings_screen.dart';
import '../screens/examples_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            tooltip: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
              _showToast('New file created');
            },
          ),
          _buildToolbarButton(
            icon: Icons.library_books,
            tooltip: 'Examples',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
            },
          ),
          _buildToolbarButton(
            icon: Icons.file_download_outlined, // Inverted: Import
            tooltip: 'Import .dart',
            onTap: () => _importFile(ref),
          ),
          _buildToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () => _copyCode(ref),
          ),
          _buildToolbarButton(
            icon: Icons.paste,
            tooltip: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onTap: () => _formatCode(ref),
          ),
          _buildToolbarButton(
            icon: Icons.file_upload_outlined, // Inverted: Export/Download
            tooltip: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          _buildToolbarButton(
            icon: Icons.share,
            tooltip: 'Share',
            onTap: () => _shareCode(ref),
          ),
          _buildToolbarButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete File',
            onTap: () => _deleteFile(context, ref),
            isDestructive: true,
          ),
          _buildToolbarButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24), // Pill shape
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.toolbarButtonBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.toolbarButtonBorder, width: 1),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppTheme.errorRed : Colors.black87,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).importFile(name, content);
        _showToast('Imported $name');
      }
    } catch (e) {
      _showToast('Error importing file');
    }
  }

  Future<void> _copyCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Clipboard.setData(ClipboardData(text: activeFile.content));
      _showToast('Code copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        String newContent = activeFile.content + (data.text ?? '');
        ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
        _showToast('Pasted from clipboard');
      }
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        String formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        _showToast('Code formatted');
      } catch (e) {
        _showToast('Error formatting code: syntax error');
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        // ignore: unused_local_variable
        final file = File('${dir.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Save your file',
        );
      } catch (e) {
        _showToast('Error downloading file');
      }
    }
  }

  Future<void> _shareCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Share.share(
        activeFile.content,
        subject: activeFile.name,
      );
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete ${activeFile.name}? This cannot be undone.', style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
      _showToast('File deleted');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.white12,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
