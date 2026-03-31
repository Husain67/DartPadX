import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:dart_style/dart_style.dart';
import 'dart:io';
import 'dart:convert';

import '../../providers/file_provider.dart';
import '../../ui/theme/theme_constants.dart';
import '../../features/settings/settings_screen.dart';

class CodeToolbar extends ConsumerWidget {
  final CodeController codeController;
  final VoidCallback forceSave;

  const CodeToolbar({super.key, required this.codeController, required this.forceSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      color: ThemeConstants.backgroundEnd,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            icon: Icons.add,
            label: 'New',
            onTap: () => _handleNewFile(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import',
            onTap: () => _handleImport(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => _handleCopy(),
          ),
          _buildToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => _handlePaste(),
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => _handleFormat(),
          ),
          _buildToolbarButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _handleExamplesGallery(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.save_alt,
            label: 'Download',
            onTap: () => _handleDownload(ref),
          ),
          _buildToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => _handleShare(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _handleDelete(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => _handleSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Material(
        color: ThemeConstants.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: ThemeConstants.toolbarButtonBorder, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: ThemeConstants.toolbarButtonIcon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: ThemeConstants.toolbarButtonIcon,
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

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'filename.dart'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim().isEmpty ? 'untitled.dart' : controller.text.trim();
                ref.read(fileProvider.notifier).addFile(name, '');
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
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
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: codeController.text));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final currentPos = codeController.selection.baseOffset;
      if (currentPos >= 0) {
        final currentText = codeController.text;
        final newText = currentText.substring(0, currentPos) +
            data!.text! +
            currentText.substring(currentPos);
        codeController.text = newText;
        codeController.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
      } else {
        codeController.text += data!.text!;
      }
      forceSave();
    }
  }

  void _handleFormat() {
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formattedCode = formatter.format(codeController.text);
      codeController.text = formattedCode;
      forceSave();
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Formatting failed (syntax error?)");
    }
  }

  void _handleExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'List Example': 'void main() {\n  var list = [1, 2, 3];\n  for (var item in list) {\n    print(item);\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() {\n    print("Hello \$name");\n  }\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.greet();\n}',
      'Async Example': 'Future<void> fetchUserOrder() {\n  return Future.delayed(const Duration(seconds: 2), () => print("Order Large Latte"));\n}\n\nvoid main() async {\n  print("Fetching user order...");\n  await fetchUserOrder();\n  print("Done");\n}'
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Examples Gallery'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: examples.length,
              itemBuilder: (context, index) {
                String key = examples.keys.elementAt(index);
                return ListTile(
                  title: Text(key),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ref.read(fileProvider.notifier).addFile('${key.replaceAll(" ", "_").toLowerCase()}.dart', examples[key]!);
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: "Loaded $key");
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
          ],
        );
      },
    );
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${activeFile.name}');
        await file.writeAsString(codeController.text);

        await Share.shareXFiles([XFile(file.path)], text: 'Download ${activeFile.name}');
      } catch (e) {
        Fluttertoast.showToast(msg: "Download failed: $e");
      }
    }
  }

  void _handleShare(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Share Raw Code'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(codeController.text, subject: 'DartMini Code');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Base64 Link'),
                onTap: () {
                  Navigator.pop(context);
                  final encoded = base64Encode(utf8.encode(codeController.text));
                  final link = "https://dartmini.ide/share?code=$encoded";
                  Clipboard.setData(ClipboardData(text: link));
                  Fluttertoast.showToast(msg: "Link copied to clipboard");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final activeFile = ref.read(fileProvider.notifier).activeFile;
                if (activeFile != null) {
                  ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                  Fluttertoast.showToast(msg: "File deleted");
                }
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}
