import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/preset_provider.dart';
import 'code_editor_widget.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1a1a1a)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(context, ref, fileState, presetState, execState),
                  _buildToolbar(context, ref, fileState),
                  _buildFileTabs(context, ref, fileState),
                  const Expanded(
                    child: CodeEditorWidget(),
                  ),
                ],
              ),
              OutputSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, FileState fileState, PresetState presetState, ExecutionState execState) {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'DartMini',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFACC15)),
            ),
            child: const Text(
              'beta',
              style: TextStyle(fontSize: 10, color: Color(0xFFFACC15), fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: execState.isExecuting ? null : () async {
              if (fileState.activeFile != null) {
                await ref.read(executionProvider.notifier).executeCode(fileState.activeFile!.content, presetState.activePreset);
              }
            },
            icon: execState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
            label: Text(execState.isExecuting ? 'Running' : 'Run', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              disabledBackgroundColor: const Color(0xFFFACC15).withOpacity(0.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref, FileState fileState) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _ToolbarButton(icon: Icons.add_box_outlined, label: 'New File', onTap: () => _newFile(context, ref)),
          _ToolbarButton(icon: Icons.file_download_outlined, label: 'Import .dart', onTap: () => _importFile(ref)),
          _ToolbarButton(icon: Icons.copy_outlined, label: 'Copy code', onTap: () => _copyCode(fileState)),
          _ToolbarButton(icon: Icons.paste_outlined, label: 'Paste', onTap: () => _pasteCode(ref)),
          _ToolbarButton(icon: Icons.download_outlined, label: 'Download .dart', onTap: () => _downloadFile(fileState)),
          _ToolbarButton(icon: Icons.share_outlined, label: 'Share', onTap: () => _shareFile(fileState)),
          _ToolbarButton(icon: Icons.delete_outline, label: 'Delete', onTap: () => _deleteFile(context, ref, fileState)),
          _ToolbarButton(icon: Icons.book_outlined, label: 'Examples', onTap: () => _openExamples(context, ref)),
          _ToolbarButton(icon: Icons.settings_outlined, label: 'Settings', onTap: () => _openSettings(context)),
        ],
      ),
    );
  }

  Widget _buildFileTabs(BuildContext context, WidgetRef ref, FileState fileState) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? const Color(0xFFFACC15) : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive && fileState.files.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _newFile(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: const Text('New File', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (val) => name = val,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'filename.dart',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  ref.read(fileProvider.notifier).createFile(name);
                }
                Navigator.pop(context);
              },
              child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        );
      },
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

        ref.read(fileProvider.notifier).createFile(name);
        ref.read(fileProvider.notifier).updateActiveFileContent(content);

        Fluttertoast.showToast(msg: "File imported successfully", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing file", backgroundColor: Colors.red);
    }
  }

  void _copyCode(FileState fileState) {
    if (fileState.activeFile != null) {
      Clipboard.setData(ClipboardData(text: fileState.activeFile!.content));
      Fluttertoast.showToast(msg: "Code copied to clipboard", backgroundColor: const Color(0xFF333333));
    }
  }

  Future<void> _pasteCode(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
      Fluttertoast.showToast(msg: "Code pasted", backgroundColor: const Color(0xFF333333));
    }
  }

  Future<void> _downloadFile(FileState fileState) async {
    if (fileState.activeFile != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/${fileState.activeFile!.name}';
        final file = File(path);
        await file.writeAsString(fileState.activeFile!.content);
        await Share.shareXFiles([XFile(path)], text: 'Downloaded from DartMini IDE');
      } catch (e) {
        Fluttertoast.showToast(msg: "Error downloading file", backgroundColor: Colors.red);
      }
    }
  }

  void _shareFile(FileState fileState) {
    if (fileState.activeFile != null) {
      Share.share(fileState.activeFile!.content, subject: 'Dart Code from DartMini IDE');
    }
  }

  void _deleteFile(BuildContext context, WidgetRef ref, FileState fileState) {
    if (fileState.activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete this file?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(fileState.activeFileId!);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "File deleted", backgroundColor: const Color(0xFF333333));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openExamples(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Examples Gallery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ExampleItem(
              title: 'Hello World',
              code: '''void main() {
  print('Hello World!');
}''',
              onSelect: (code) => _loadExample(context, ref, 'hello.dart', code),
            ),
            _ExampleItem(
              title: 'Input / Output',
              code: '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}''',
              onSelect: (code) => _loadExample(context, ref, 'io.dart', code),
            ),
            _ExampleItem(
              title: 'Lists & Loops',
              code: '''void main() {
  List<String> fruits = ['Apple', 'Banana', 'Cherry'];
  for (var fruit in fruits) {
    print('I like \$fruit');
  }
}''',
              onSelect: (code) => _loadExample(context, ref, 'lists.dart', code),
            ),
            _ExampleItem(
              title: 'Classes',
              code: '''class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('Hi, I am \$name and I am \$age years old.');
  }
}

void main() {
  var p = Person('Alice', 25);
  p.introduce();
}''',
              onSelect: (code) => _loadExample(context, ref, 'class.dart', code),
            ),
            _ExampleItem(
              title: 'Async / Await',
              code: '''Future<void> main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 2));
  print('Data fetched!');
}''',
              onSelect: (code) => _loadExample(context, ref, 'async.dart', code),
            ),
          ],
        );
      },
    );
  }

  void _loadExample(BuildContext context, WidgetRef ref, String name, String code) {
    ref.read(fileProvider.notifier).createFile(name);
    ref.read(fileProvider.notifier).updateActiveFileContent(code);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Example loaded", backgroundColor: const Color(0xFF333333));
  }
}

class _ExampleItem extends StatelessWidget {
  final String title;
  final String code;
  final Function(String) onSelect;

  const _ExampleItem({required this.title, required this.code, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => onSelect(code),
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
              color: const Color(0xFFF9F9F9), // White/cream background
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1), // Thin border
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
