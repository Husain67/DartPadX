
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: AppTheme.primaryAccent,
      textColor: Colors.black,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildBtn(Icons.add, "New", () => _newFile(context, ref)),
          _buildBtn(Icons.format_align_left, "Format", () => _formatCode(ref)),
          _buildBtn(Icons.library_books, "Examples", () => _showExamples(context, ref)),
          _buildBtn(Icons.file_download, "Import", () => _importFile(ref)),
          _buildBtn(Icons.copy, "Copy", () => _copyCode(ref)),
          _buildBtn(Icons.paste, "Paste", () => _pasteCode(ref)),
          _buildBtn(Icons.download, "Download", () => _downloadFile(ref)),
          _buildBtn(Icons.share, "Share", () => _shareCode(ref)),
          _buildBtn(Icons.delete, "Delete", () => _deleteFile(context, ref)),
          _buildBtn(Icons.settings, "Settings", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }


  void _formatCode(WidgetRef ref) {
    // Basic format simulation since dart_style package needs synchronous string replacement
    final active = ref.read(fileProvider).activeFile;
    if (active != null) {
      // Simplistic placeholder for formatting
      String formatted = active.content.replaceAll(';}', ';\n}');
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      final state = ref.read(fileProvider);
      ref.read(fileProvider.notifier).forceSyncState(state.copyWith(files: List.from(state.files)));
      _showToast('Code Formatted');
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello World!");\n}',
      'List Example': 'void main() {\n  var list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n  void sayHi() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.sayHi();\n}',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Examples'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: examples.entries.map((e) => ListTile(
              title: Text(e.key),
              onTap: () {
                ref.read(fileProvider.notifier).createNewFile('${e.key.replaceAll(' ', '_').toLowerCase()}.dart');
                ref.read(fileProvider.notifier).updateActiveFileContent(e.value);
                final state = ref.read(fileProvider);
                ref.read(fileProvider.notifier).forceSyncState(state.copyWith(files: List.from(state.files)));
                Navigator.pop(ctx);
              },
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
              border: Border.all(color: Colors.grey.shade300),
            ),
            alignment: Alignment.center,
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    String name = 'untitled.dart';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('New File'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'File name (e.g. main.dart)'),
          onChanged: (v) => name = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) {
                ref.read(fileProvider.notifier).createNewFile(name.endsWith('.dart') ? name : '$name.dart');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFile(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        String name = result.files.single.name;

        ref.read(fileProvider.notifier).createNewFile(name);
        ref.read(fileProvider.notifier).updateActiveFileContent(content);
        // Force state update to sync text controller
        final state = ref.read(fileProvider);
        ref.read(fileProvider.notifier).forceSyncState(state.copyWith(files: List.from(state.files)));

        _showToast('Imported $name');
      }
    } catch (e) {
      _showToast('Error importing file');
    }
  }

  void _copyCode(WidgetRef ref) {
    final active = ref.read(fileProvider).activeFile;
    if (active != null) {
      Clipboard.setData(ClipboardData(text: active.content));
      _showToast('Copied to clipboard');
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
       ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
       final state = ref.read(fileProvider);
       ref.read(fileProvider.notifier).forceSyncState(state.copyWith(files: List.from(state.files)));
       _showToast('Pasted');
    }
  }

  Future<void> _downloadFile(WidgetRef ref) async {
    final active = ref.read(fileProvider).activeFile;
    if (active == null) return;

    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final file = File('${dir.path}/${active.name}');
        await file.writeAsString(active.content);
        _showToast('Saved to ${file.path}');
      }
    } catch (e) {
      _showToast('Failed to save file');
    }
  }

  void _shareCode(WidgetRef ref) {
    final active = ref.read(fileProvider).activeFile;
    if (active != null) {
      Share.share(active.content, subject: active.name);
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              _showToast('File deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
