import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../services/storage_service.dart';
import '../screens/settings_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Toolbar extends ConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile();
            },
          ),
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onTap: () async {
              final result = await StorageService().pickDartFile();
              if (result != null) {
                ref.read(fileProvider.notifier).importFile(result['name']!, result['content']!);
              }
            },
          ),
          _ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onTap: () {
              // We'll hook this up to the clipboard later via the active controller
              Fluttertoast.showToast(msg: "Use editor's copy feature");
            },
          ),
          _ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onTap: () {
              // We'll hook this up to the clipboard later
              Fluttertoast.showToast(msg: "Use editor's paste feature");
            },
          ),
          _ToolbarButton(
            icon: Icons.arrow_downward,
            label: 'Download .dart',
            onTap: () async {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 final path = await StorageService().downloadFile(activeFile.name, activeFile.content);
                 if (path != null) {
                   Fluttertoast.showToast(msg: "Saved to \$path");
                 }
               }
            },
          ),
          _ToolbarButton(
            icon: Icons.link,
            label: 'Share',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 StorageService().shareCodeAsDeepLink(activeFile.content);
               }
            },
          ),
          _ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _showDeleteDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              Fluttertoast.showToast(msg: "Format Code (Stub)");
            },
          ),
          _ToolbarButton(
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
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this file?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFileById(activeFile.id);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
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
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
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
}
