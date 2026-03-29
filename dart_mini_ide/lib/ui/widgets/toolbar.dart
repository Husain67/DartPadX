import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../../core/constants.dart';
import '../screens/settings_screen.dart';

class CodeToolbar extends ConsumerWidget {
  const CodeToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => ref.read(fileProvider.notifier).addFile(),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () => _importFile(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _showExamplesGallery(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () => _copyCode(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _formatCode(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onTap: () => _downloadFile(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareCode(ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppConstants.errorColor,
            onTap: () => _deleteFile(context, ref),
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    try {
      final List<dynamic> examples = jsonDecode(AppConstants.examplesGalleryJson);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.bgColorEnd,
          title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: examples.length,
              itemBuilder: (context, index) {
                final example = examples[index];
                return ListTile(
                  title: Text(example['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.add_circle_outline, color: AppConstants.accentColor),
                  onTap: () {
                    ref.read(fileProvider.notifier).addFile(
                      name: '${example['name'].toString().toLowerCase().replaceAll(' ', '_')}.dart',
                      content: example['code'],
                    );
                    Navigator.pop(ctx);
                    Fluttertoast.showToast(msg: "Example loaded");
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load examples");
    }
  }

  void _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        ref.read(fileProvider.notifier).addFile(name: name, content: content);
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed");
    }
  }

  void _copyCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  void _pasteCode(WidgetRef ref) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  void _formatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format error: syntax error");
      }
    }
  }

  void _downloadFile(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final Directory dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        await Share.shareXFiles([XFile(file.path)], text: 'Download ${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed");
      }
    }
  }

  void _shareCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: activeFile.name);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgColorEnd,
        title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${activeFile.name}? This cannot be undone.',
          style: TextStyle(color: Colors.white.withValues(alpha: 255 * 0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
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

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppConstants.toolbarBtnBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppConstants.toolbarBtnBorder),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
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
