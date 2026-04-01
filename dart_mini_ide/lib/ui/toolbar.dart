import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/file_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.backgroundEnd,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import',
            onTap: () => _handleImportFile(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _handleCopy(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.file_download,
            label: 'Download',
            onTap: () => _handleDownload(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _handleFormatCode(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _showExamplesDialog(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
            color: AppColors.outputStderr,
          ),
          _buildToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => _handleSettings(context),
          ),
        ],
      ),
    );
  }

  void _handleFormatCode(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, formattedCode);
        Fluttertoast.showToast(msg: 'Code formatted');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Syntax error: could not format code');
      }
    }
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Examples Gallery'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: AppConstants.examples.length,
            itemBuilder: (context, index) {
              final key = AppConstants.examples.keys.elementAt(index);
              final code = AppConstants.examples[key]!;
              return ListTile(
                title: Text(key, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.add_circle_outline, color: AppColors.accentYellow),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('${key.replaceAll(' ', '_').toLowerCase()}.dart', code);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: 'Example loaded');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color ?? AppColors.toolbarButtonText),
        label: Text(
          label,
          style: TextStyle(color: color ?? AppColors.toolbarButtonText),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.toolbarButtonBg,
          foregroundColor: AppColors.toolbarButtonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.toolbarButtonBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    int counter = ref.read(fileProvider).files.length + 1;
    ref.read(fileProvider.notifier).addFile('untitled$counter.dart', '');
    Fluttertoast.showToast(msg: 'New file created');
  }

  Future<void> _handleImportFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;

        ref.read(fileProvider.notifier).addFile(name, content);
        Fluttertoast.showToast(msg: 'File imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to import file: $e');
    }
  }

  void _handleCopy(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: 'Code copied to clipboard');
    }
  }

  Future<void> _handlePaste(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        final currentContent = activeFile.content;
        final newContent = currentContent + data.text!;
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, newContent);
        Fluttertoast.showToast(msg: 'Code pasted');
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/${activeFile.name}';
        final file = File(filePath);
        await file.writeAsString(activeFile.content);

        await Share.shareXFiles([XFile(filePath)], text: 'Download ${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to download file: $e');
      }
    }
  }

  void _handleShare(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      final fakeDeepLink = 'dartmini://share?code=$base64Code';
      Share.share('Check out my Dart code on DartMini IDE: $fakeDeepLink');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outputStderr,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}