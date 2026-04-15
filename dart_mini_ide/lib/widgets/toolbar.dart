import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dart_style/dart_style.dart';

import '../providers/file_provider.dart';
import '../screens/examples_gallery_screen.dart';

class CustomToolbar extends ConsumerWidget {
  const CustomToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildButton(
              icon: Icons.add,
              label: 'New File',
              onTap: () => ref.read(fileProvider.notifier).createFile(),
            ),
            _buildButton(
              icon: Icons.photo_album_outlined,
              label: 'Examples',
              onTap: () => _openExamples(context),
            ),
            _buildButton(
              icon: Icons.file_download_outlined,
              label: 'Import',
              onTap: () => _importFile(ref),
            ),
            _buildButton(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () => _copyCode(ref),
            ),
            _buildButton(
              icon: Icons.paste,
              label: 'Paste',
              onTap: () => _pasteCode(ref),
            ),
            _buildButton(
              icon: Icons.auto_fix_high,
              label: 'Format',
              onTap: () => _formatCode(ref),
            ),
            _buildButton(
              icon: Icons.download,
              label: 'Download',
              onTap: () => _downloadFile(ref),
            ),
            _buildButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () => _shareCode(ref),
            ),
            _buildButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              iconColor: Colors.redAccent,
              onTap: () => _deleteFile(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: const Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
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

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        ref.read(fileProvider.notifier).createFile(result.files.single.name, content);
        Fluttertoast.showToast(msg: "File Imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import file");
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      final newContent = activeFile.content + (clipboardData!.text ?? '');
      ref.read(fileProvider.notifier).updateActiveFileContent(newContent);
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(activeFile.content);
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format");
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${activeFile.name}');
      await tempFile.writeAsString(activeFile.content);

      await Share.shareXFiles([XFile(tempFile.path)]);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to download/share file");
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final base64Code = base64Encode(utf8.encode(activeFile.content));
    Share.share('Check out this code snippet:\n\nbase64:$base64Code');
  }

  void _openExamples(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExamplesGalleryScreen()),
    );
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeFileId = ref.read(fileProvider).activeFileId;
    if (activeFileId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete this file? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFileId);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
