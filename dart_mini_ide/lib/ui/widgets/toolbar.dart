import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64, // Slightly taller for touch targets
      color: const Color(0xFF0A0A0A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _ToolbarButton(
            icon: Icons.add,
            label: 'New',
            onTap: () => _createNewFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.file_upload_outlined,
            label: 'Import',
            onTap: () => _importFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _copyCode(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _pasteCode(ref),
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () => _downloadFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _shareFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () => _deleteFile(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  void _createNewFile(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) {
       return AlertDialog(
         backgroundColor: const Color(0xFF1E1E1E),
         title: const Text('New File', style: TextStyle(color: Colors.white)),
         content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'filename.dart',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
            ),
         ),
         actions: [
           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
           TextButton(onPressed: () {
             ref.read(fileProvider.notifier).addFile(controller.text.isEmpty ? 'untitled.dart' : controller.text, '');
             Navigator.pop(context);
           }, child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15)))),
         ],
       );
    });
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['dart']);
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null) {
            final file = File(path);
            final content = await file.readAsString();
            ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
        }
      }
    } catch (e) {
      debugPrint('Error importing file: $e');
    }
  }

  void _copyCode(BuildContext context, WidgetRef ref) {
    final content = ref.read(currentFileProvider)?.content ?? '';
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
       final index = ref.read(currentFileIndexProvider);
       final currentContent = ref.read(currentFileProvider)?.content ?? '';
       // Appending for simplicity as we don't have cursor position here
       ref.read(fileProvider.notifier).updateFileContent(index, '$currentContent\n${data!.text!}');
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
      _shareFile(ref); // Mobile download usually means share/save to files
  }

  Future<void> _shareFile(WidgetRef ref) async {
    final file = ref.read(currentFileProvider);
    if (file != null) {
      final directory = await getTemporaryDirectory();
      final tempFile = File('${directory.path}/${file.name}');
      await tempFile.writeAsString(file.content);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Check out my Dart code!');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
      content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () {
           final index = ref.read(currentFileIndexProvider);
           ref.read(fileProvider.notifier).deleteFile(index).then((_) {
               final count = ref.read(fileProvider).length;
               if (index >= count) {
                   ref.read(currentFileIndexProvider.notifier).state = count > 0 ? count - 1 : 0;
               }
           });
           Navigator.pop(context);
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
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
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEEEEEE), // Cream/White
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), // Pill shape
          minimumSize: const Size(0, 40),
          elevation: 0,
          side: BorderSide(color: Colors.grey.shade400, width: 0.5),
        ),
      ),
    );
  }
}
