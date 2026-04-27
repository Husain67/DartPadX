import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/file_helper.dart';
import 'code_editor.dart';
import 'output_sheet.dart';
import 'settings_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/examples.dart';


class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execState = ref.watch(executionProvider);
    final fileState = ref.watch(fileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by main app gradient
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: execState.isRunning
                  ? null
                  : () {
                      final activeFile = fileState.activeFile;
                      if (activeFile != null) {
                        final preset = ref.read(settingsProvider).activePreset;
                        if (preset != null) {
                           ref.read(executionProvider.notifier).executeCode(activeFile.content, preset);
                        } else {
                           Fluttertoast.showToast(msg: "No compiler preset selected");
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: execState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildToolbar(context, ref),
              _buildFileTabs(ref),
              const Expanded(child: CodeEditorArea()),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [

          _ToolbarButton(
            icon: Icons.book,
            label: 'Examples',
            onTap: () => _showExamplesDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.note_add,
            label: 'New',
            onTap: () => _showNewFileDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.file_download,
            label: 'Import',
            onTap: () => FileHelper.importFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy',
            onTap: () => FileHelper.copyActiveFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () => FileHelper.pasteToActiveFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () => FileHelper.downloadActiveFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () => FileHelper.shareActiveFile(ref),
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _confirmDelete(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () => ref.read(fileProvider.notifier).formatActiveFile(),
          ),
          _ToolbarButton(
            icon: Icons.clear_all,
            label: 'Clear Output',
            onTap: () => ref.read(executionProvider.notifier).clearOutput(),
          ),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTabs(WidgetRef ref) {
    final state = ref.watch(fileProvider);
    return Container(
      height: 40,
      color: Colors.black54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;
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
              alignment: Alignment.center,
              child: Text(
                file.name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showExamplesDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Examples Gallery', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: Examples.gallery.length,
            itemBuilder: (context, index) {
              final key = Examples.gallery.keys.elementAt(index);
              return ListTile(
                title: Text(key, style: const TextStyle(color: Color(0xFFFACC15))),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('${key.replaceAll(" ", "_").toLowerCase()}.dart', Examples.gallery[key]!);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showNewFileDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: 'untitled.dart');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('New File', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Filename (e.g. test.dart)',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(fileProvider.notifier).addFile(controller.text, '');
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFFACC15))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final state = ref.read(fileProvider);
    if (state.activeFileId == null) return;

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
              ref.read(fileProvider.notifier).deleteFile(state.activeFileId!);
              Fluttertoast.showToast(msg: "File deleted");
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Material(
        color: const Color(0xFFF9F9F9),
        shape: const StadiumBorder(side: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
