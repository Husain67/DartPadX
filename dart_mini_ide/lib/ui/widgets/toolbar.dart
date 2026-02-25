import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/file_provider.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/code_editor.dart';
import '../screens/settings_screen.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileNotifier = ref.read(fileProvider.notifier);
    final currentFile = ref.watch(fileProvider);
    final controller = ref.watch(activeEditorControllerProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ToolbarButton(
            icon: Icons.add,
            tooltip: 'New File',
            onTap: () => _showNewFileDialog(context, ref),
          ),
          ToolbarButton(
            icon: Icons.file_upload_outlined, // Import
            tooltip: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart'],
              );

              if (result != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                String name = result.files.single.name;
                await fileNotifier.createNewFile(name, content);
                Fluttertoast.showToast(msg: "Imported $name");
              }
            },
          ),
          ToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () {
              if (controller != null) {
                Clipboard.setData(ClipboardData(text: controller.text));
                Fluttertoast.showToast(msg: "Copied to clipboard");
              }
            },
          ),
          ToolbarButton(
            icon: Icons.paste,
            tooltip: 'Paste',
            onTap: () async {
              if (controller != null) {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  // Insert at cursor or replace selection
                  final text = data!.text!;
                  final selection = controller.selection;
                  final newText = controller.text.replaceRange(
                    selection.start,
                    selection.end,
                    text,
                  );
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: selection.start + text.length),
                  );
                  Fluttertoast.showToast(msg: "Pasted");
                }
              }
            },
          ),
          ToolbarButton(
            icon: Icons.download,
            tooltip: 'Download .dart',
            onTap: () async {
              if (currentFile != null) {
                final directory = await getTemporaryDirectory();
                final file = File('${directory.path}/${currentFile.name}');
                await file.writeAsString(currentFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Download ${currentFile.name}');
              }
            },
          ),
          ToolbarButton(
            icon: Icons.share,
            tooltip: 'Share Code',
            onTap: () {
              if (currentFile != null) {
                Share.share(currentFile.content, subject: currentFile.name);
              }
            },
          ),
          ToolbarButton(
            icon: Icons.delete_outline,
            tooltip: 'Delete File',
            color: Colors.redAccent,
            onTap: () => _showDeleteDialog(context, ref),
          ),
          ToolbarButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'File Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(fileProvider.notifier).createNewFile(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteCurrentFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
