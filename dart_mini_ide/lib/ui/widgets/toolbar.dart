import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

import '../../core/theme.dart';
import '../../providers/file_provider.dart';
import '../settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.transparent, // Background handled by parent gradient
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.add_box_outlined,
              label: 'New',
              onPressed: () {
                ref.read(fileProvider.notifier).addNewFile();
                _showToast('New file created');
              },
            ),
            _ToolButton(
              icon: Icons.file_download_outlined,
              label: 'Import',
              onPressed: () => _importFile(ref),
            ),
            _ToolButton(
              icon: Icons.copy_outlined,
              label: 'Copy',
              onPressed: () => _copyCode(ref),
            ),
            _ToolButton(
              icon: Icons.paste_outlined,
              label: 'Paste',
              onPressed: () => _pasteCode(ref),
            ),
            _ToolButton(
              icon: Icons.auto_fix_high,
              label: 'Format',
              onPressed: () => _formatCode(ref),
            ),
            _ToolButton(
              icon: Icons.download_outlined,
              label: 'Save',
              onPressed: () => _downloadFile(ref),
            ),
            _ToolButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onPressed: () => _shareCode(ref),
            ),
            _ToolButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onPressed: () => _deleteFile(context, ref),
            ),
            _ToolButton(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppTheme.primaryAccent,
      textColor: AppTheme.pureBlack,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        final content = utf8.decode(file.bytes!);
        ref.read(fileProvider.notifier).addNewFile(
          name: file.name,
          content: content,
        );
        _showToast('Imported ${file.name}');
      }
    } catch (e) {
      _showToast('Import failed: $e');
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
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content + (data!.text ?? ''));
        _showToast('Code pasted');
      }
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        _showToast('Code formatted');
      } catch (e) {
        _showToast('Syntax error, could not format');
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = '${dir.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        _showToast('Saved to $path');
      }
    } catch (e) {
      _showToast('Save failed: $e');
    }
  }

  Future<void> _shareCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Share.share(activeFile.content, subject: 'Shared from DartMini IDE');
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      ref.read(fileProvider.notifier).deleteActiveFile();
      _showToast('File deleted');
    }
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: const Color(0xFFFDFBF7), // white/cream background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.textMuted.withOpacity(0.2)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppTheme.pureBlack), // Dark icon for cream background
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.pureBlack, // Dark text for cream background
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
}
