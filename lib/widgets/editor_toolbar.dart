import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_style/dart_style.dart';
import '../widgets/examples_gallery.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(fileProvider).activeFile;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildBtn(context, Icons.note_add, 'New File', () {
            ref.read(fileProvider.notifier).createNewFile();
          }),
          _buildBtn(context, Icons.file_download, 'Import', () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final content = await file.readAsString();
                final fileNotifier = ref.read(fileProvider.notifier);
                fileNotifier.createNewFile();
                final newActiveFile = ref.read(fileProvider).activeFile;
                if (newActiveFile != null) {
                  fileNotifier.forceUpdateFile(newActiveFile.copyWith(
                    name: result.files.single.name,
                    content: content,
                  ));
                }
                Fluttertoast.showToast(msg: "File imported");
              }
            } catch (e) {
              Fluttertoast.showToast(msg: "Error importing file");
            }
          }),
          _buildBtn(context, Icons.library_books, 'Examples', () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const ExamplesGallery(),
            );
          }),
          _buildBtn(context, Icons.format_align_left, 'Format', () {
            if (activeFile != null) {
              try {
                final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                final formattedCode = formatter.format(activeFile.content);
                // force update to bypass controller listener debounce loop
                ref.read(fileProvider.notifier).forceUpdateFile(activeFile.copyWith(content: formattedCode));
                Fluttertoast.showToast(msg: "Code formatted");
              } catch (e) {
                Fluttertoast.showToast(msg: "Syntax error: Cannot format");
              }
            }
          }),
          _buildBtn(context, Icons.copy, 'Copy', () {
            if (activeFile != null) {
              Clipboard.setData(ClipboardData(text: activeFile.content));
              Fluttertoast.showToast(msg: "Copied to clipboard");
            }
          }),
          _buildBtn(context, Icons.paste, 'Paste', () async {
            if (activeFile != null) {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
                Fluttertoast.showToast(msg: "Pasted from clipboard");
              }
            }
          }),
          _buildBtn(context, Icons.download, 'Download', () async {
            if (activeFile != null) {
              try {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                Fluttertoast.showToast(msg: "Downloaded to ${file.path}");
              } catch (e) {
                Fluttertoast.showToast(msg: "Error downloading file");
              }
            }
          }),
          _buildBtn(context, Icons.share, 'Share', () {
            if (activeFile != null) {
              final encoded = base64Encode(utf8.encode(activeFile.content));
              Share.share('dartmini://code?data=$encoded', subject: activeFile.name);
            }
          }),
          _buildBtn(context, Icons.delete, 'Delete', () async {
            if (activeFile == null) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1a1a1a),
                title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
                content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Fluttertoast.showToast(msg: "File deleted");
            }
          }),
          _buildBtn(context, Icons.settings, 'Settings', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8E8), // white/cream
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87, size: 20),
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
    );
  }
}
