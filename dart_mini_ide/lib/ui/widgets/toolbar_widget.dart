import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../../utils/constants.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolBtn(Icons.add, 'New File', () => _newFile(context, ref)),
          _buildToolBtn(Icons.download_rounded, 'Import', () => _importFile(ref)),
          _buildToolBtn(Icons.copy, 'Copy', () => _copyCode(ref)),
          _buildToolBtn(Icons.paste, 'Paste', () => _pasteCode(ref)),
          _buildToolBtn(Icons.file_download, 'Download', () => _downloadFile(ref)),
          _buildToolBtn(Icons.share, 'Share', () => _shareCode(ref)),
          _buildToolBtn(Icons.format_align_left, 'Format', () => _formatCode(ref)),
          _buildToolBtn(Icons.delete_outline, 'Delete', () => _deleteFile(context, ref), isDestructive: true),
          _buildToolBtn(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildToolBtn(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: AppColors.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.toolbarButtonBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: isDestructive ? AppColors.errorRed : Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? AppColors.errorRed : Colors.black87,
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

  void _newFile(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'filename.dart'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              var name = controller.text.trim();
              if (name.isNotEmpty) {
                if (!name.endsWith('.dart') && !name.endsWith('.txt')) {
                  name += '.dart';
                }
                ref.read(fileProvider.notifier).addFile(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        ref.read(fileProvider.notifier).addFile(result.files.single.name, content: content);
        Fluttertoast.showToast(msg: 'Imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing file');
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: 'Pasted successfully');
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        await Share.shareXFiles([XFile(path)], text: 'Exported from DartMini IDE');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Error exporting file');
      }
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      Share.share('Check out my Dart code!\n\nBase64:\n$base64Code');
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error, cannot format');
      }
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete this file?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'File deleted');
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        ),
      );
    }
  }
}
