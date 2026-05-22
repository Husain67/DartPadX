import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  final Function(String) onCodeImported;

  const EditorToolbar({Key? key, required this.onCodeImported}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(editorProvider).activeFile;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ToolbarBtn(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          _ToolbarBtn(
            icon: Icons.file_download,
            label: 'Import .dart',
            onTap: () => _handleImport(context, ref),
          ),

          _ToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: activeFile == null ? null : () => _handleFormat(context, ref, activeFile.content),
          ),
          _ToolbarBtn(
            icon: Icons.copy,
            label: 'Copy',
            onTap: activeFile == null ? null : () => _handleCopy(activeFile.content),
          ),
          _ToolbarBtn(
            icon: Icons.paste,
            label: 'Paste',
            onTap: activeFile == null ? null : () => _handlePaste(context, ref),
          ),
          _ToolbarBtn(
            icon: Icons.download,
            label: 'Download',
            onTap: activeFile == null ? null : () => _handleDownload(activeFile.name, activeFile.content),
          ),
          _ToolbarBtn(
            icon: Icons.share,
            label: 'Share',
            onTap: activeFile == null ? null : () => _handleShare(activeFile.name, activeFile.content),
          ),
          _ToolbarBtn(
            icon: Icons.delete_outline,
            label: 'Delete',
            iconColor: Colors.red,
            onTap: activeFile == null ? null : () => _handleDelete(context, ref, activeFile.id),
          ),
          _ToolbarBtn(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.grey[900],
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        String name = '';
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g., helpers.dart'),
            onChanged: (val) => name = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                   if (!name.endsWith('.dart')) name += '.dart';
                   ref.read(editorProvider.notifier).createFile(name);
                   Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      }
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;
        ref.read(editorProvider.notifier).importFile(name, content);
        _showToast('Imported $name');
      }
    } catch (e) {
      _showToast('Import failed: $e');
    }
  }


  void _handleFormat(BuildContext context, WidgetRef ref, String content) {
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(content);
      onCodeImported(formatted);
      _showToast('Code formatted');
    } catch (e) {
      _showToast('Format error: Invalid Dart syntax');
    }
  }

  Future<void> _handleCopy(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    _showToast('Copied to clipboard');
  }

  Future<void> _handlePaste(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      onCodeImported(data.text!);
      _showToast('Pasted from clipboard');
    }
  }

  Future<void> _handleDownload(String name, String content) async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
         dir = Directory('/storage/emulated/0/Download');
         if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
         dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        File file = File('${dir.path}/$name');
        await file.writeAsString(content);
        _showToast('Saved to ${file.path}');
      }
    } catch (e) {
      _showToast('Download failed: $e');
    }
  }

  Future<void> _handleShare(String name, String content) async {
    final base64Code = base64Encode(utf8.encode(content));
    final link = 'dartmini://share?code=$base64Code';
    await Share.share('Check out my Dart code:\n\n$content\n\nOpen in DartMini: $link', subject: name);
  }

  void _handleDelete(BuildContext context, WidgetRef ref, String fileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(editorProvider.notifier).deleteFile(fileId);
              Navigator.pop(ctx);
              _showToast('File deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      )
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _ToolbarBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.toolbarButtonBorder, width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: iconColor ?? AppTheme.toolbarButtonIcon),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor ?? AppTheme.toolbarButtonIcon,
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
