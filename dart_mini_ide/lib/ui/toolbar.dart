import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/file_provider.dart';
import '../services/file_service.dart';
import 'settings_screen.dart';
import 'examples_screen.dart';

class EditorToolbar extends ConsumerWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.black,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.lightbulb_outline,
            label: 'Examples',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamplesGallery()));
            },
          ),
          _ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () => ref.read(fileProvider.notifier).createNewFile(),
          ),
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () async {
              final result = await FileService.importFile();
              if (result != null) {
                ref.read(fileProvider.notifier).createNewFile();
                final activeFile = ref.read(fileProvider.notifier).activeFile;
                if (activeFile != null) {
                  ref.read(fileProvider.notifier).updateActiveFileContent(result['content']!);
                }
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () async {
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                await FileService.copyToClipboard(activeFile.content);
                Fluttertoast.showToast(msg: 'Copied to clipboard');
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () async {
              final content = await FileService.pasteFromClipboard();
              if (content != null) {
                ref.read(fileProvider.notifier).updateActiveFileContent(content);
                // Force state copy to trigger Riverpod listen update in editor

                ref.read(fileProvider.notifier).forceUiUpdate();
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                final formatted = FileService.formatCode(activeFile.content);
                ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                // Force state copy to trigger Riverpod listen update in editor

                ref.read(fileProvider.notifier).forceUiUpdate();
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.download,
            label: 'Download',
            onTap: () async {
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                await FileService.downloadFile(activeFile.name, activeFile.content);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onTap: () async {
              final activeFile = ref.read(fileProvider.notifier).activeFile;
              if (activeFile != null) {
                await FileService.shareFileContent(activeFile.name, activeFile.content);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: () => _confirmDelete(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this file?'),
        content: Text('Delete "${activeFile.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'File deleted');
            },
            child: const Text('Delete'),
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

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
