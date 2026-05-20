import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/file_provider.dart';
import '../theme.dart';
import '../screens/settings_screen.dart';
import 'package:dart_style/dart_style.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: AppTheme.darkGray,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolButton(
            icon: Icons.add,
            tooltip: 'New File',
            onPressed: () => _handleNewFile(context, ref),
          ),
          _buildToolButton(
            icon: Icons.download,
            tooltip: 'Import .dart',
            onPressed: () => _handleImport(context, ref),
          ),
          _buildToolButton(
            icon: Icons.list_alt,
            tooltip: 'Examples',
            onPressed: () => _showExamples(context, ref),
          ),
          _buildToolButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onPressed: () => _handleFormat(ref),
          ),
          _buildToolButton(
            icon: Icons.copy,
            tooltip: 'Copy code',
            onPressed: () => _handleCopy(ref),
          ),
          _buildToolButton(
            icon: Icons.paste,
            tooltip: 'Paste',
            onPressed: () => _handlePaste(ref),
          ),
          _buildToolButton(
            icon: Icons.file_download,
            tooltip: 'Download .dart',
            onPressed: () => _handleDownload(ref),
          ),
          _buildToolButton(
            icon: Icons.share,
            tooltip: 'Share',
            onPressed: () => _handleShare(ref),
          ),
          _buildToolButton(
            icon: Icons.delete,
            tooltip: 'Delete current file',
            onPressed: () => _handleDelete(context, ref),
          ),
          _buildToolButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.whiteCream,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.pureBlack, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter file name (e.g. hello.dart)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(controller.text, '', 'dart');
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).addFile(result.files.single.name, content, 'dart');
    }
  }

  void _handleCopy(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Copied to clipboard");
    }
  }

  Future<void> _handlePaste(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data != null && data.text != null) {
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, data.text!);
        ref.read(fileProvider.notifier).forceUpdate();
        Fluttertoast.showToast(msg: "Pasted from clipboard");
      }
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to $path");
    }
  }

  void _handleShare(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final encoded = base64Encode(utf8.encode(activeFile.content));
      Share.share('Check out my dart code: dartmini://code?data=$encoded');
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete this file?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(activeFile.id);
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

  void _handleFormat(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formatter = DartFormatter(); // Using DartFormatter without args for older version
        final formatted = formatter.format(activeFile.content);
        ref.read(fileProvider.notifier).updateFileContent(activeFile.id, formatted);
        ref.read(fileProvider.notifier).forceUpdate();
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Format failed (syntax error?)");
      }
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGray,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            const SizedBox(height: 16),
            _exampleTile(context, ref, 'Hello World', '''void main() {
  print('Hello World');
}'''),
            _exampleTile(context, ref, 'Input Output', '''import 'dart:io';
void main() {
  print('Enter something:');
  String? input = stdin.readLineSync();
  print('You entered: \${input}');
}'''),
            _exampleTile(context, ref, 'List', '''void main() {
  var list = [1, 2, 3];
  list.add(4);
  print(list);
}'''),
            _exampleTile(context, ref, 'Class', '''class Person {
  String name;
  Person(this.name);
  void greet() => print('Hello \${name}');
}
void main() {
  var p = Person('Alice');
  p.greet();
}'''),
            _exampleTile(context, ref, 'Async', '''Future<void> delayedPrint() async {
  await Future.delayed(Duration(seconds: 1));
  print('Done');
}
void main() async {
  print('Waiting...');
  await delayedPrint();
}'''),
          ],
        );
      }
    );
  }

  Widget _exampleTile(BuildContext context, WidgetRef ref, String title, String code) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        ref.read(fileProvider.notifier).addFile('${title.replaceAll(' ', '_').toLowerCase()}.dart', code, 'dart');
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Loaded $title example");
      },
    );
  }
}
