with open('lib/ui/main_screen.dart', 'r') as f:
    content = f.read()

import_statement = """import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';"""

content = content.replace("import 'package:flutter/services.dart';", import_statement)

toolbar_buttons = """          _ToolbarButton(icon: Icons.add, label: 'New', onTap: () => _handleNewFile(context, ref)),
          _ToolbarButton(icon: Icons.download_rounded, label: 'Import', onTap: () => _handleImport(ref)),
          _ToolbarButton(icon: Icons.format_align_left, label: 'Format', onTap: () => _handleFormat(ref)),
          _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: () => _handleCopy(ref)),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: () => _handlePaste(ref)),
          _ToolbarButton(icon: Icons.download, label: 'Download', onTap: () => _handleDownload(ref)),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: () => _handleShare(ref)),
          _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: () => _handleDelete(context, ref)),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),"""

content = content.replace("""          _ToolbarButton(icon: Icons.add, label: 'New', onTap: () => _handleNewFile(context, ref)),
          _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: () => _handleCopy(ref)),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: () => _handlePaste(ref)),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: () => _handleShare(ref)),
          _ToolbarButton(icon: Icons.delete, label: 'Delete', onTap: () => _handleDelete(context, ref)),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),""", toolbar_buttons)

handlers = """  void _handleNewFile(BuildContext context, WidgetRef ref) {
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
  }"""

content = content.replace("""  void _handleNewFile(BuildContext context, WidgetRef ref) {
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
  }""", handlers)

with open('lib/ui/main_screen.dart', 'w') as f:
    f.write(content)
