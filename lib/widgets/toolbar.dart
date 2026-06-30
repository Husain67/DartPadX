import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dart_style/dart_style.dart';
import '../providers/file_provider.dart';
import '../providers/output_provider.dart';
import '../screens/settings_screen.dart';
import '../theme.dart';
import '../utils/examples.dart';

class IdeToolbar extends ConsumerWidget {
  const IdeToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton(
            icon: Icons.add_box,
            tooltip: 'New File',
            onPressed: () => _handleNewFile(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.file_download,
            tooltip: 'Import .dart',
            onPressed: () => _handleImport(ref),
          ),
          _buildToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onPressed: () => _handleCopy(ref),
          ),
          _buildToolbarButton(
            icon: Icons.paste,
            tooltip: 'Paste Code',
            onPressed: () => _handlePaste(ref),
          ),
          _buildToolbarButton(
            icon: Icons.download,
            tooltip: 'Download .dart',
            onPressed: () => _handleDownload(ref),
          ),
          _buildToolbarButton(
            icon: Icons.share,
            tooltip: 'Share',
            onPressed: () => _handleShare(ref),
          ),
          _buildToolbarButton(
            icon: Icons.delete,
            tooltip: 'Delete File',
            onPressed: () => _handleDelete(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.code,
            tooltip: 'Examples',
            onPressed: () => _handleExamples(context, ref),
          ),
          _buildToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onPressed: () => _handleFormatCode(ref),
          ),
          _buildToolbarButton(
            icon: Icons.clear_all,
            tooltip: 'Clear Output',
            onPressed: () => _handleClearOutput(ref),
          ),
          _buildToolbarButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleExamples(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Examples'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: Examples.collection.length,
              itemBuilder: (context, index) {
                final key = Examples.collection.keys.elementAt(index);
                return ListTile(
                  title: Text(key),
                  onTap: () {
                    ref.read(fileProvider.notifier).addFile('$key.dart', content: Examples.collection[key]!);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleFormatCode(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      try {
        final formattedCode = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(activeFile.content);
        ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
        Fluttertoast.showToast(msg: "Code formatted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Syntax error, couldn't format");
      }
    }
  }

  void _handleClearOutput(WidgetRef ref) {
    ref.read(outputProvider.notifier).clear();
    Fluttertoast.showToast(msg: "Output cleared");
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.toolbarButtonBg,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }

  void _handleNewFile(BuildContext context, WidgetRef ref) {
    String fileName = 'untitled.dart';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'File Name'),
            onChanged: (val) => fileName = val,
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(val);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (fileName.isNotEmpty) {
                  ref.read(fileProvider.notifier).addFile(fileName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImport(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = String.fromCharCodes(result.files.single.bytes!);
        String name = result.files.single.name;
        ref.read(fileProvider.notifier).addFile(name, content: content);
        Fluttertoast.showToast(msg: "File imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file: $e");
    }
  }

  void _handleCopy(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard");
    }
  }

  Future<void> _handlePaste(WidgetRef ref) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: "Code pasted");
    }
  }

  Future<void> _handleDownload(WidgetRef ref) async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Fallback to Download folder if possible
        String newPath = "";
        List<String> paths = directory!.path.split("/");
        for (int x = 1; x < paths.length; x++) {
          String folder = paths[x];
          if (folder != "Android") {
            newPath += "/$folder";
          } else {
            break;
          }
        }
        newPath = "$newPath/Download";
        directory = Directory(newPath);
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File("${directory.path}/${activeFile.name}");
        await saveFile.writeAsString(activeFile.content);
        Fluttertoast.showToast(msg: "File saved to ${directory.path}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving file: $e");
    }
  }

  void _handleShare(WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: 'Dart Code: ${activeFile.name}');
    }
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
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteActiveFile();
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "File deleted");
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
