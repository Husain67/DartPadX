import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../screens/settings_screen.dart';
import 'examples_dialog.dart';

class EditorToolbar extends ConsumerWidget {
  final TextEditingController? textController;
  const EditorToolbar({Key? key, this.textController}) : super(key: key);

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.white24,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.note_add,
            label: "New File",
            onTap: () {
              ref.read(fileProvider.notifier).addFile('untitled.dart', '');
              _showToast("New file created");
            },
          ),
          _ToolbarButton(
            icon: Icons.folder,
            label: "Examples",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const ExamplesDialog(),
              );
            },
          ),
          _ToolbarButton(
            icon: Icons.file_download,
            label: "Import",
            onTap: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['dart', 'txt'],
                  withData: true,
                );
                if (result != null && result.files.single.bytes != null) {
                  final content = String.fromCharCodes(result.files.single.bytes!);
                  ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
                  _showToast("File imported");
                }
              } catch (e) {
                _showToast("Failed to import file");
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: "Format",
            onTap: () {
              if (textController != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formattedCode = formatter.format(textController!.text);
                  textController!.text = formattedCode;
                  final currentId = ref.read(currentFileIdProvider);
                  if (currentId != null) {
                    ref.read(fileProvider.notifier).updateFileContent(currentId, formattedCode);
                  }
                  _showToast("Code formatted");
                } catch (e) {
                  _showToast("Syntax error: Cannot format");
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: "Copy",
            onTap: () {
              if (textController != null) {
                Clipboard.setData(ClipboardData(text: textController!.text));
                _showToast("Code copied");
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: "Paste",
            onTap: () async {
              if (textController != null) {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  final text = data!.text!;
                  final sel = textController!.selection;
                  if (sel.isValid) {
                    final newText = textController!.text.replaceRange(sel.start, sel.end, text);
                    textController!.text = newText;
                    textController!.selection = TextSelection.collapsed(offset: sel.start + text.length);
                  } else {
                    textController!.text += text;
                  }
                  final currentId = ref.read(currentFileIdProvider);
                  if (currentId != null) {
                    ref.read(fileProvider.notifier).updateFileContent(currentId, textController!.text);
                  }
                  _showToast("Pasted");
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: "Download",
            onTap: () async {
              if (textController != null && textController!.text.isNotEmpty) {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final currentId = ref.read(currentFileIdProvider);
                  final fileModel = ref.read(fileProvider).firstWhere((f) => f.id == currentId);
                  final file = File('${directory.path}/${fileModel.name}');
                  await file.writeAsString(textController!.text);
                  _showToast("Saved to \${file.path}");
                } catch (e) {
                  _showToast("Failed to save file");
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.clear_all,
            label: "Clear Output",
            onTap: () {
              ref.read(executionProvider.notifier).clearOutput();
              _showToast("Output cleared");
            },
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: "Share",
            onTap: () {
              if (textController != null && textController!.text.isNotEmpty) {
                Share.share(textController!.text);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: "Delete",
            onTap: () {
              final currentId = ref.read(currentFileIdProvider);
              if (currentId == null) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete this file?"),
                  content: const Text("This cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(fileProvider.notifier).deleteFile(currentId);
                        final files = ref.read(fileProvider);
                        if (files.isNotEmpty) {
                          ref.read(currentFileIdProvider.notifier).state = files.first.id;
                        } else {
                          ref.read(fileProvider.notifier).addFile('untitled.dart', '');
                          ref.read(currentFileIdProvider.notifier).state = ref.read(fileProvider).first.id;
                        }
                        Navigator.pop(context);
                        _showToast("File deleted");
                      },
                      child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
          _ToolbarButton(
            icon: Icons.settings,
            label: "Settings",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.black12, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
        ),
      ),
    );
  }
}
