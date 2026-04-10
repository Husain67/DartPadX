import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../theme.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _ToolbarButton(
            icon: Icons.add,
            label: 'New',
            onTap: () => _handleNewFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import',
            onTap: () => _handleImport(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _handleCopy(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.auto_fix_high,
            label: 'Format',
            onTap: () => _handleFormat(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Save as .dart',
            onTap: () => _handleDownload(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
          ),
          _ToolbarButton(
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

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File Name'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isNotEmpty) {
                if (!name.endsWith('.dart') && !name.endsWith('.txt')) {
                  name += '.dart';
                }
                ref.read(fileProvider.notifier).addFile(name: name, content: '');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
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
        ref.read(fileProvider.notifier).addFile(name: name, content: content);
        Fluttertoast.showToast(msg: 'File imported', backgroundColor: AppTheme.accentYellow, textColor: Colors.black);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    }
  }

  Future<void> _handleCopy(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied!', backgroundColor: AppTheme.accentYellow, textColor: Colors.black);
    }
  }

  Future<void> _handlePaste(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final notifier = ref.read(fileProvider.notifier);
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null) {
        notifier.updateActiveFileContent(activeFile.content + data.text!);
        Fluttertoast.showToast(msg: 'Pasted successfully', backgroundColor: AppTheme.accentYellow, textColor: Colors.black);
      }
    }
  }

  void _handleFormat(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: 'Code formatted', backgroundColor: AppTheme.accentYellow, textColor: Colors.black);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error, cannot format', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        await Share.shareXFiles([XFile(file.path)], text: 'Exported from DartMini IDE');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Export failed: $e');
      }
    }
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      final link = 'dartmini://share?code=$base64Code';
      await Share.share('Check out my Dart code: $link');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted', backgroundColor: Colors.red);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.toolbarButtonBorder, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.toolbarButtonText),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.toolbarButtonText,
                    fontSize: 13,
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
