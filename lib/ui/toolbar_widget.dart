import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_notifier.dart';
import '../services/io_service.dart';
import 'package:dart_style/dart_style.dart';
import 'settings_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToolbarWidget extends ConsumerWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarBtn(
            icon: Icons.add,
            label: 'New File',
            onTap: () => ref.read(filesProvider.notifier).createNewFile(),
          ),
          _ToolbarBtn(
            icon: Icons.library_books,
            label: 'Examples',
            onTap: () => _showExamplesGallery(context, ref),
          ),
          _ToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final state = ref.read(filesProvider);
              if (state.activeFileId != null) {
                final file = state.files.firstWhere((f) => f.id == state.activeFileId);
                try {
                  final formatted = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion).format(file.content);
                  ref.read(filesProvider.notifier).updateActiveFileContent(formatted);
                  Fluttertoast.showToast(msg: 'Code formatted', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Format failed (syntax error?)', backgroundColor: Colors.red, textColor: Colors.white);
                }
              }
            },
          ),

          _ToolbarBtn(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () async {
              final result = await IOService.importFile();
              if (result != null) {
                ref.read(filesProvider.notifier).importFile(result['name']!, result['content']!);
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () {
              final state = ref.read(filesProvider);
              if (state.activeFileId != null) {
                final file = state.files.firstWhere((f) => f.id == state.activeFileId);
                IOService.copyToClipboard(file.content);
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final state = ref.read(filesProvider);
              if (state.activeFileId != null) {
                final clipboard = await IOService.pasteFromClipboard();
                if (clipboard != null && clipboard.isNotEmpty) {
                  final file = state.files.firstWhere((f) => f.id == state.activeFileId);
                  final newContent = '${file.content}\n$clipboard';
                  ref.read(filesProvider.notifier).updateActiveFileContent(newContent);
                  Fluttertoast.showToast(msg: 'Pasted successfully', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
                }
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.download,
            label: 'Download .dart',
            onTap: () {
              final state = ref.read(filesProvider);
              if (state.activeFileId != null) {
                final file = state.files.firstWhere((f) => f.id == state.activeFileId);
                IOService.downloadFile(file.name, file.content);
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.share,
            label: 'Share',
            onTap: () {
              final state = ref.read(filesProvider);
              if (state.activeFileId != null) {
                final file = state.files.firstWhere((f) => f.id == state.activeFileId);
                IOService.shareCode(file.content);
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.delete,
            label: 'Delete file',
            onTap: () => _showDeleteDialog(context, ref),
          ),
          _ToolbarBtn(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              ref.read(filesProvider.notifier).deleteActiveFile();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'File deleted', backgroundColor: Colors.red, textColor: Colors.white);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC), // white/cream
          borderRadius: BorderRadius.circular(24), // pill shape
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
  void _showExamplesGallery(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print(\'Hello World!\');\n}',
      'List Example': 'void main() {\n  final list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n}\n\nvoid main() {\n  var p = Person(\'Alice\');\n  print(p.name);\n}',
      'Async Example': 'Future<void> main() async {\n  print(\'Waiting...\');\n  await Future.delayed(Duration(seconds: 1));\n  print(\'Done!\');\n}',
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Examples Gallery'),
        backgroundColor: const Color(0xFF1a1a1a),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: examples.length,
            itemBuilder: (c, i) {
              final key = examples.keys.elementAt(i);
              return ListTile(
                title: Text(key),
                onTap: () {
                  ref.read(filesProvider.notifier).importFile('$key.dart', examples[key]!);
                  Navigator.pop(ctx);
                  Fluttertoast.showToast(msg: 'Example loaded', backgroundColor: const Color(0xFFFACC15), textColor: Colors.black);
                },
              );
            },
          ),
        ),
      ),
    );
  }
