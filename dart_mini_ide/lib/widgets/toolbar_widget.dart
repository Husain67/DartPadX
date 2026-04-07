import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dart_style/dart_style.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme.dart';
import '../screens/settings_screen.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  Widget _buildBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.toolbarButtonBg,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.toolbarButtonBorder, width: 1),
            ),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
        ),
      ),
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
          _buildBtn(Icons.add, 'New File', () {
            ref.read(fileProvider.notifier).createNewFile();
          }),
          _buildBtn(Icons.file_download, 'Import .dart', () {
            // Basic import dummy implementation for scope
            Fluttertoast.showToast(msg: "Import file feature");
          }),
          _buildBtn(Icons.copy, 'Copy code', () {
            final active = ref.read(fileProvider).activeFile;
            if (active != null) {
              Clipboard.setData(ClipboardData(text: active.content));
              Fluttertoast.showToast(msg: "Copied to clipboard");
            }
          }),
          _buildBtn(Icons.paste, 'Paste', () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
               ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
            }
          }),
          _buildBtn(Icons.download, 'Download .dart', () async {
             final active = ref.read(fileProvider).activeFile;
             if (active != null) {
               final tempDir = await getTemporaryDirectory();
               final file = File('${tempDir.path}/${active.name}');
               await file.writeAsString(active.content);
               Share.shareXFiles([XFile(file.path)], text: 'Download ${active.name}');
             }
          }),
          _buildBtn(Icons.share, 'Share', () {
             final active = ref.read(fileProvider).activeFile;
             if (active != null) {
               final encoded = base64Encode(utf8.encode(active.content));
               Clipboard.setData(ClipboardData(text: encoded));
               Fluttertoast.showToast(msg: "Base64 copied to clipboard");
             }
          }),
          _buildBtn(Icons.delete, 'Delete current file', () {
             final active = ref.read(fileProvider).activeFile;
             if (active != null) {
               showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Delete this file?'),
                   content: const Text('This cannot be undone.'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                     TextButton(onPressed: () {
                       ref.read(fileProvider.notifier).deleteFile(active.id);
                       Navigator.pop(ctx);
                       Fluttertoast.showToast(msg: "File deleted");
                     }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                   ],
                 )
               );
             }
          }),
          _buildBtn(Icons.format_align_left, 'Format Code', () {
             final active = ref.read(fileProvider).activeFile;
             if (active != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formatted = formatter.format(active.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                  Fluttertoast.showToast(msg: "Code formatted");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Syntax error: Cannot format");
                }
             }
          }),
          _buildBtn(Icons.book, 'Examples Gallery', () {
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text('Examples'),
                 content: SingleChildScrollView(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       ListTile(title: const Text('Hello World'), onTap: () { ref.read(fileProvider.notifier).createNewFile('hello.dart', "void main() { print('Hello World'); }"); Navigator.pop(ctx); }),
                       ListTile(title: const Text('List Example'), onTap: () { ref.read(fileProvider.notifier).createNewFile('list.dart', "void main() { var list = [1, 2, 3]; print(list); }"); Navigator.pop(ctx); }),
                       ListTile(title: const Text('Class Example'), onTap: () { ref.read(fileProvider.notifier).createNewFile('class.dart', "class Person { String name; Person(this.name); } void main() { var p = Person('Dart'); print(p.name); }"); Navigator.pop(ctx); }),
                     ],
                   ),
                 ),
               )
             );
          }),
          _buildBtn(Icons.clear_all, 'Clear Output', () {
             ref.read(executionProvider.notifier).clearOutput();
          }),
          _buildBtn(Icons.settings, 'Settings', () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }
}
