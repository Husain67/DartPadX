import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/file_provider.dart';
import '../core/theme.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppTheme.backgroundColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBtn(Icons.add, 'New', () => ref.read(fileProvider.notifier).createNewFile()),
          _buildBtn(Icons.download_rounded, 'Import', () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                ref.read(fileProvider.notifier).importFile(result.files.single.name, content);
              }
            } catch (e) {
              Fluttertoast.showToast(msg: 'Error importing file');
            }
          }),
          _buildBtn(Icons.copy, 'Copy', () {
            final active = ref.read(fileProvider).activeFile;
            if (active != null) {
              Clipboard.setData(ClipboardData(text: active.content));
              Fluttertoast.showToast(msg: 'Copied to clipboard');
            }
          }),
          _buildBtn(Icons.paste, 'Paste', () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
              final currentContent = ref.read(fileProvider).activeFile?.content ?? '';
              ref.read(fileProvider.notifier).updateActiveFileContent(currentContent + data.text!);
            }
          }),
          _buildBtn(Icons.download, 'Download', () async {
            final active = ref.read(fileProvider).activeFile;
            if (active != null) {
              try {
                final dir = await getApplicationDocumentsDirectory();
                final file = File('${dir.path}/${active.name}');
                await file.writeAsString(active.content);
                Fluttertoast.showToast(msg: 'Saved to ${file.path}');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Error saving file');
              }
            }
          }),
          _buildBtn(Icons.share, 'Share', () {
            final active = ref.read(fileProvider).activeFile;
            if (active != null) {
              final b64 = base64Encode(utf8.encode(active.content));
              Share.share('dartmini://code?data=$b64');
            }
          }),
          _buildBtn(Icons.delete, 'Delete', () {
            final active = ref.read(fileProvider).activeFile;
            if (active != null) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete this file?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        ref.read(fileProvider.notifier).deleteFile(active.id);
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: 'File deleted');
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          }),
          _buildBtn(Icons.settings, 'Settings', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
