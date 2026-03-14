import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../providers/file_provider.dart';
import '../utils/theme.dart';
import '../screens/settings_screen.dart';
import 'package:dart_style/dart_style.dart';

class MainToolbar extends ConsumerWidget {
  const MainToolbar({Key? key}) : super(key: key);

  void _createNewFile(WidgetRef ref, BuildContext context) {
    int nextId = ref.read(fileProvider).files.length + 1;
    ref.read(fileProvider.notifier).addFile('untitled$nextId.dart', '// New file\n');
  }

  Future<void> _importFile(WidgetRef ref, BuildContext context) async {
    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final name = result.files.single.name;
        ref.read(fileProvider.notifier).addFile(name, content);
        Fluttertoast.showToast(msg: "Imported $name", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e", backgroundColor: Colors.red);
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard", backgroundColor: Colors.green);
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        // We broadcast an Intent that the EditorShell's Actions can intercept,
        // or since flutter_code_editor handles paste on its own textfield via native OS,
        // we can simply use the clipboard data to append at cursor position if we had access to the controller.
        // For a decoupled approach without direct controller access, we append to the end
        // unless we expose the controller. Let's append to the end for now and let native OS handle in-editor paste.
        // To properly implement "Paste at cursor", the controller needs to handle it.
        // For now, we will notify the user they can paste directly in the editor to use cursor position,
        // or we append it if they use the toolbar.
        final currentContent = activeFile.content;
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, currentContent + clipboardData.text!);
        Fluttertoast.showToast(msg: "Appended from clipboard. (Tip: Use OS paste inside editor for cursor placement)", backgroundColor: Colors.green);
      }
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${activeFile.name}');
      await file.writeAsString(activeFile.content);
      await Share.shareXFiles([XFile(file.path)], text: 'Download ${activeFile.name}');
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final base64Code = base64Encode(utf8.encode(activeFile.content));
      Share.share('Check out my Dart code!\nBase64:\n$base64Code');
    }
  }

  void _deleteFile(WidgetRef ref, BuildContext context) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete File'),
          content: const Text('Delete this file? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "File deleted");
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, formatted);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Syntax error, couldn't format", backgroundColor: Colors.red);
      }
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPillButton(Icons.add, 'New', () => _createNewFile(ref, context)),
          _buildPillButton(Icons.download_rounded, 'Import', () => _importFile(ref, context)),
          _buildPillButton(Icons.copy, 'Copy', () => _copyCode(ref)),
          _buildPillButton(Icons.paste, 'Paste', () => _pasteCode(ref)),
          _buildPillButton(Icons.save_alt, 'Download', () => _downloadFile(ref)),
          _buildPillButton(Icons.share, 'Share', () => _shareCode(ref)),
          _buildPillButton(Icons.format_align_left, 'Format', () => _formatCode(ref)),
          _buildPillButton(Icons.delete, 'Delete', () => _deleteFile(ref, context), isDestructive: true),
          _buildPillButton(Icons.settings, 'Settings', () => _openSettings(context)),
        ],
      ),
    );
  }

  Widget _buildPillButton(IconData icon, String label, VoidCallback onPressed, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.toolbarButtonBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isDestructive ? Colors.red : AppTheme.textDark),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : AppTheme.textDark,
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
