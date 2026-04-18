import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import 'toolbar_button.dart';
import '../settings/settings_screen.dart';
import 'examples_gallery.dart';

class MainToolbar extends ConsumerWidget {
  const MainToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CustomToolbarButton(
            icon: Icons.add,
            tooltip: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
              Fluttertoast.showToast(msg: "New file created");
            },
          ),
          CustomToolbarButton(
            icon: Icons.file_download,
            tooltip: 'Import .dart',
            onTap: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['dart', 'txt'],
              );
              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                ref.read(fileProvider.notifier).createNewFile(result.files.single.name, content);
                Fluttertoast.showToast(msg: "File imported");
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.copy,
            tooltip: 'Copy Code',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                Clipboard.setData(ClipboardData(text: activeFile.content));
                Fluttertoast.showToast(msg: "Code copied to clipboard");
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.paste,
            tooltip: 'Paste',
            onTap: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null && data.text != null) {
                final activeFile = ref.read(fileProvider).activeFile;
                if (activeFile != null) {
                  ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content + data.text!);
                  Fluttertoast.showToast(msg: "Pasted from clipboard");
                }
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.download,
            tooltip: 'Download .dart',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                await Share.shareXFiles([XFile(file.path)], text: 'Download ${activeFile.name}');
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.share,
            tooltip: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final encoded = base64Encode(utf8.encode(activeFile.content));
                Share.share('Check out my Dart code! dartmini://code?data=$encoded');
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.delete,
            tooltip: 'Delete File',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete File?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
                          Navigator.pop(ctx);
                          Fluttertoast.showToast(msg: "File deleted");
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.photo_library,
            tooltip: 'Examples Gallery',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesGallery()));
            },
          ),
          CustomToolbarButton(
            icon: Icons.format_align_left,
            tooltip: 'Format Code',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formattedCode = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
                  Fluttertoast.showToast(msg: "Code formatted");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Syntax error, could not format code");
                }
              }
            },
          ),
          CustomToolbarButton(
            icon: Icons.settings,
            tooltip: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
