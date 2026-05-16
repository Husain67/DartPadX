import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import '../widgets/editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

final stdinProvider = StateProvider<String>((ref) => '');

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  void _runCode() {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.files.firstWhere((f) => f.id == fileState.activeFileId);
    final stdin = ref.read(stdinProvider);
    ref.read(executionProvider.notifier).executeCode(activeFile.content, stdin);
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: Colors.grey, width: 0.5)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      ref.read(fileProvider.notifier).createFile(result.files.single.name, content: content);
      Fluttertoast.showToast(msg: "File imported");
    }
  }

  void _copyCode() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    Clipboard.setData(ClipboardData(text: activeFile.content));
    Fluttertoast.showToast(msg: "Copied to clipboard");
  }

  Future<void> _pasteCode() async {
    final ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: "Pasted from clipboard");
    }
  }

  Future<void> _downloadFile() async {
    try {
      final activeFile = ref.read(fileProvider.notifier).activeFile;
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(activeFile.content);
      Fluttertoast.showToast(msg: "Saved to \$path");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error downloading: \$e");
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    final encoded = base64Encode(utf8.encode(activeFile.content));
    Share.share('Check out my Dart code on DartMini IDE!\ndartmini://code?c=\\$encoded');
  }

  void _deleteFile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this file?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final activeFileId = ref.read(fileProvider).activeFileId;
              ref.read(fileProvider.notifier).deleteFile(activeFileId);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning ? null : _runCode,
              icon: execState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: const StadiumBorder(),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 60,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  children: [
                    _buildToolbarButton(Icons.add_box, "New File", () => ref.read(fileProvider.notifier).createFile('untitled.dart')),
                    _buildToolbarButton(Icons.collections_bookmark, "Examples", () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => ListView(
                          children: [
                            const ListTile(title: Text('Examples Gallery', style: TextStyle(fontWeight: FontWeight.bold))),
                            ListTile(title: const Text('Hello World'), onTap: () {
                              ref.read(fileProvider.notifier).createFile('hello.dart', content: 'void main() {\n  print("Hello World!");\n}');
                              Navigator.pop(context);
                            }),
                            ListTile(title: const Text('Input/Output'), onTap: () {
                              ref.read(fileProvider.notifier).createFile('io.dart', content: 'import "dart:io";\n\nvoid main() {\n  print("Enter name:");\n  String? n = stdin.readLineSync();\n  print("Hi \$n");\n}');
                              Navigator.pop(context);
                            }),
                            ListTile(title: const Text('List & Map'), onTap: () {
                              ref.read(fileProvider.notifier).createFile('list.dart', content: 'void main() {\n  var l = [1, 2, 3];\n  print(l);\n}');
                              Navigator.pop(context);
                            }),
                            ListTile(title: const Text('Classes'), onTap: () {
                              ref.read(fileProvider.notifier).createFile('class.dart', content: 'class Person {\n  String name;\n  Person(this.name);\n}\n\nvoid main() {\n  var p = Person("Dart");\n  print(p.name);\n}');
                              Navigator.pop(context);
                            }),
                            ListTile(title: const Text('Async / Await'), onTap: () {
                              ref.read(fileProvider.notifier).createFile('async.dart', content: 'Future<void> main() async {\n  print("Waiting...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Done!");\n}');
                              Navigator.pop(context);
                            }),
                          ],
                        )
                      );
                    }),
                    _buildToolbarButton(Icons.format_align_left, "Format", () => ref.read(fileProvider.notifier).formatActiveFile()),
                    _buildToolbarButton(Icons.download, "Import .dart", _importFile),
                    _buildToolbarButton(Icons.copy, "Copy code", _copyCode),
                    _buildToolbarButton(Icons.paste, "Paste", _pasteCode),
                    _buildToolbarButton(Icons.file_download, "Download .dart", _downloadFile),
                    _buildToolbarButton(Icons.share, "Share", _shareCode),
                    _buildToolbarButton(Icons.delete, "Delete", _deleteFile),
                    _buildToolbarButton(Icons.settings, "Settings", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),
              const Expanded(child: EditorWidget()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }
}
