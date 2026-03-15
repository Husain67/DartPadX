import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildPillButton(
            icon: Icons.add,
            label: 'New',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildPillButton(
            icon: Icons.file_download_outlined,
            label: 'Import',
            onTap: () => _handleImport(context, ref),
          ),
          _buildPillButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _handleCopy(context, ref),
          ),
          _buildPillButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(context, ref),
          ),
          _buildPillButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () => _handleDownload(context, ref),
          ),
          _buildPillButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(context, ref),
          ),
          _buildPillButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _handleFormat(context, ref),
          ),
          _buildPillButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.black87),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNewFile(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'filename.dart',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(nameController.text, '// \${nameController.text}\\n');
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
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
        Fluttertoast.showToast(msg: "File imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: \$e");
    }
  }

  Future<void> _handleCopy(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      await Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied");
    }
  }

  Future<void> _handlePaste(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      final activeFile = ref.read(fileProvider).activeFile;
      if (activeFile != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content + data.text!);
        Fluttertoast.showToast(msg: "Pasted");
      }
    }
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final path = '\${dir.path}/\${activeFile.name}';
        final file = File(path);
        await file.writeAsString(activeFile.content);
        Share.shareXFiles([XFile(path)], text: 'Download \${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed: \$e");
      }
    }
  }

  Future<void> _handleShare(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
    }
  }

  Future<void> _handleFormat(BuildContext context, WidgetRef ref) async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Formatting failed. Check for syntax errors.");
      }
    }
  }
}
