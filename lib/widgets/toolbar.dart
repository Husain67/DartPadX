import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

class ToolbarWidget extends ConsumerWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onFormatTap;

  const ToolbarWidget({
    super.key,
    required this.onSettingsTap,
    required this.onFormatTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _buildButton('New File', Icons.add_circle_outline, () {
            ref.read(fileProvider.notifier).createNewFile();
            UiUtils.showToast('New file created');
          }),
          _buildButton('Import .dart', Icons.download_outlined, () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                await ref.read(fileProvider.notifier).createNewFile(content);
                UiUtils.showToast('File imported');
              }
            } catch (e) {
              UiUtils.showToast('Failed to import file', isError: true);
            }
          }),
          _buildButton('Copy code', Icons.copy, () {
            final content = ref.read(fileProvider.notifier).activeFile?.content ?? '';
            Clipboard.setData(ClipboardData(text: content));
            UiUtils.showToast('Code copied to clipboard');
          }),
          _buildButton('Paste', Icons.paste, () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null) {
               final current = ref.read(fileProvider.notifier).activeFile?.content ?? '';
               ref.read(fileProvider.notifier).updateActiveFileContent(current + data!.text!);
               UiUtils.showToast('Code pasted');
            }
          }),
          _buildButton('Format', Icons.format_align_left, onFormatTap),
          _buildButton('Download .dart', Icons.save_alt, () async {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile == null) return;
            try {
              Directory? dir;
              if (Platform.isAndroid) {
                dir = Directory('/storage/emulated/0/Download');
                if (!await dir.exists()) dir = await getExternalStorageDirectory();
              } else {
                dir = await getApplicationDocumentsDirectory();
              }
              if (dir != null) {
                final path = '\${dir.path}/\${activeFile.name}';
                final file = File(path);
                await file.writeAsString(activeFile.content);
                UiUtils.showToast('Saved to \$path');
              }
            } catch (e) {
              UiUtils.showToast('Failed to save file', isError: true);
            }
          }),
          _buildButton('Share', Icons.share, () {
            final activeFile = ref.read(fileProvider.notifier).activeFile;
            if (activeFile != null) {
               final base64Code = base64Encode(utf8.encode(activeFile.content));
               Share.share('Check out my Dart code on DartMini IDE:\n\ndartmini://code?data=\$base64Code');
            }
          }),
          _buildButton('Delete', Icons.delete_outline, () async {
            final activeId = ref.read(fileProvider).activeFileId;
            if (activeId == null) return;
            final confirm = await UiUtils.showConfirmDialog(
              context,
              title: 'Delete File',
              content: 'Delete this file? This cannot be undone.',
              isDestructive: true,
              confirmText: 'Delete',
            );
            if (confirm == true) {
              ref.read(fileProvider.notifier).deleteFile(activeId);
              UiUtils.showToast('File deleted');
            }
          }),
          _buildButton('Settings', Icons.settings, onSettingsTap),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 1),
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
