import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';

import '../../core/constants.dart';
import '../../providers/file_provider.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildToolButton(
            icon: Icons.add_circle_outline,
            label: 'New',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildToolButton(
            icon: Icons.download_for_offline_outlined,
            label: 'Import',
            onTap: () => _handleImport(context, ref),
          ),
          _buildToolButton(
            icon: Icons.copy_outlined,
            label: 'Copy',
            onTap: () => _handleCopy(ref),
          ),
          _buildToolButton(
            icon: Icons.paste_outlined,
            label: 'Paste',
            onTap: () => _handlePaste(ref),
          ),
          _buildToolButton(
            icon: Icons.file_download_outlined,
            label: 'Download',
            onTap: () => _handleDownload(ref),
          ),
          _buildToolButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _handleShare(ref),
          ),
          _buildToolButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.outputRed,
            onTap: () => _handleDelete(context, ref),
          ),
          _buildToolButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          _buildToolButton(
            icon: Icons.format_align_left_outlined,
            label: 'Format',
            onTap: () => _handleFormat(ref),
          ),
          _buildToolButton(
            icon: Icons.library_books_outlined,
            label: 'Examples',
            color: AppColors.accent,
            onTap: () => _showExamples(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.pureBlack,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            width: AppConstants.toolbarButtonSize,
            height: AppConstants.toolbarButtonSize,
            decoration: BoxDecoration(
              color: AppColors.buttonBackground,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: AppColors.buttonBorder, width: 1.0),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Filename (e.g., test.dart)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              String name = controller.text.trim();
              if (name.isEmpty) name = 'untitled.dart';
              ref.read(fileProvider.notifier).createFile(name);
              Navigator.pop(context);
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
      allowedExtensions: ['dart', 'txt', 'json'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).createFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: "Imported ${result.files.single.name}");
    }
  }

  void _handleCopy(WidgetRef ref) {
    final code = ref.read(fileProvider).currentFile?.content ?? '';
    Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(msg: "Code copied to clipboard");
  }

  Future<void> _handlePaste(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final currentCode = ref.read(fileProvider).currentFile?.content ?? '';
      ref.read(fileProvider.notifier).updateCurrentFileContent(currentCode + data!.text!);
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final file = ref.read(fileProvider).currentFile;
    if (file == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/${file.name}');
      await tempFile.writeAsString(file.content);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'Download ${file.name}');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to download");
    }
  }

  void _handleShare(WidgetRef ref) {
    final code = ref.read(fileProvider).currentFile?.content ?? '';
    Share.share(code, subject: 'DartMini Code Snippet');
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Delete this file? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteCurrentFile();
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.outputRed)),
          ),
        ],
      ),
    );
  }

  void _handleFormat(WidgetRef ref) {
    final code = ref.read(fileProvider).currentFile?.content ?? '';
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(code);
      ref.read(fileProvider.notifier).updateCurrentFileContent(formatted);
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error, cannot format");
    }
  }

  void _showExamples(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print(\'Hello World!\');\n}',
      'Input/Output': 'import \'dart:io\';\n\nvoid main() {\n  print(\'Enter your name:\');\n  // Note: stdin.readLineSync() may not work on basic web APIs without proper stdin mapping.\n  // String? name = stdin.readLineSync();\n  String name = \'Dart Coder\';\n  print(\'Hello, \$name!\');\n}',
      'List Example': 'void main() {\n  List<String> fruits = [\'Apple\', \'Banana\', \'Mango\'];\n  for (var fruit in fruits) {\n    print(\'I like \$fruit\');\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  int age;\n\n  Person(this.name, this.age);\n\n  void greet() {\n    print(\'Hi, I am \$name and I am \$age years old.\');\n  }\n}\n\nvoid main() {\n  var p = Person(\'Alice\', 30);\n  p.greet();\n}',
      'Async Example': 'Future<void> main() async {\n  print(\'Fetching data...\');\n  await Future.delayed(Duration(seconds: 2));\n  print(\'Data fetched successfully!\');\n}',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code Examples'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: examples.length,
            itemBuilder: (context, index) {
              final title = examples.keys.elementAt(index);
              final code = examples.values.elementAt(index);
              return ListTile(
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                onTap: () {
                  ref.read(fileProvider.notifier).createFile('${title.replaceAll(" ", "_").toLowerCase()}.dart', code);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: "$title loaded");
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
