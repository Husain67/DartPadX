import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'editor_widget.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: executionState.isLoading ? null : () => ref.read(executionProvider.notifier).runCode(),
              icon: executionState.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildToolbar(context, ref),
                const Expanded(child: EditorWidget()),
              ],
            ),
            if (executionState.isOutputVisible)
              const OutputSheet(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          _ToolbarButton(icon: Icons.add, label: 'New', onTap: () => _handleNewFile(context, ref)),
          _ToolbarButton(icon: Icons.download_rounded, label: 'Import', onTap: () => _handleImport(ref)),
          _ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: () => _handleFormat(ref)),
          _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: () => _handleCopy(ref)),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: () => _handlePaste(ref)),
          _ToolbarButton(icon: Icons.download, label: 'Download', onTap: () => _handleDownload(ref)),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: () => _handleShare(ref)),
          _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: () => _handleDelete(context, ref)),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).createFile(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).createFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: "Imported ${result.files.single.name}");
    }
  }

  void _handleFormat(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter();
        final formattedCode = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).forceUpdateContent(activeFile.id, formattedCode);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed: Syntax error");
      }
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${activeFile.name}');
        await file.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "Saved to ${file.path}");
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to download");
      }
    }
  }

  void _handleCopy(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  void _handlePaste(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        ref.read(fileProvider.notifier).forceUpdateContent(activeFile.id, data!.text!);
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  void _handleShare(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Dart Code: \${activeFile.name}');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
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
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
