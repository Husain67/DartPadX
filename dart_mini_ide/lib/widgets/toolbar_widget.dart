import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';
import '../screens/examples_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPillButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _showNewFileDialog(context, ref),
          ),
          _buildPillButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () => _importDartFile(context, ref),
          ),
          _buildPillButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _copyCode(ref),
          ),
          _buildPillButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _buildPillButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          _buildPillButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          _buildPillButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
            onTap: () => _deleteCurrentFile(context, ref),
          ),
          _buildPillButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamplesScreen()),
              );
            },
          ),
          _buildPillButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: AppTheme.pillBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: AppTheme.pillBorder, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : AppTheme.pureBlack,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : AppTheme.pureBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundEnd,
          title: const Text('New File', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'filename.dart',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim().isEmpty ? 'untitled.dart' : controller.text.trim();
                ref.read(fileProvider.notifier).createFile(name);
                Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: AppTheme.primaryAccent)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importDartFile(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;

        ref.read(fileProvider.notifier).createFile(name, content);
        Fluttertoast.showToast(msg: 'File imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to import file: \$e');
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        // Find cursor or just append? We'll replace for simplicity here if no selection,
        // but since we want external paste support, we'll replace entire content
        // OR append if user prefers. Let's just append at bottom for safety,
        // or actually replacing entire file is often expected if it's empty.
        final currentContent = activeFile.content;
        final newContent = currentContent.isEmpty ? data.text! : '\$currentContent\n\${data.text!}';
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, newContent);
        Fluttertoast.showToast(msg: 'Code pasted');
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);

        await Share.shareXFiles([XFile(file.path)], text: 'Download \${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to download: \$e');
      }
    }
  }

  Future<void> _shareCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      // Just share the raw text
      Share.share(activeFile.content, subject: 'Dart snippet: \${activeFile.name}');
    }
  }

  void _deleteCurrentFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundEnd,
          title: const Text('Delete File', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Delete this file? This cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'File deleted');
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
