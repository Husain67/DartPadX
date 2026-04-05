import 'package:flutter/material.dart';

class CustomToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CustomToolbarButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

class EditorToolbar extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;
  final VoidCallback onFormat;

  const EditorToolbar({
    super.key,
    required this.onNewFile,
    required this.onImport,
    required this.onCopy,
    required this.onPaste,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.onSettings,
    required this.onFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            CustomToolbarButton(icon: Icons.add, onTap: onNewFile),
            CustomToolbarButton(icon: Icons.file_download_outlined, onTap: onImport),
            CustomToolbarButton(icon: Icons.copy, onTap: onCopy),
            CustomToolbarButton(icon: Icons.paste, onTap: onPaste),
            CustomToolbarButton(icon: Icons.download_outlined, onTap: onDownload),
            CustomToolbarButton(icon: Icons.share, onTap: onShare),
            CustomToolbarButton(icon: Icons.delete_outline, onTap: onDelete),
            CustomToolbarButton(icon: Icons.format_align_left, onTap: onFormat),
            CustomToolbarButton(icon: Icons.book, onTap: () => Navigator.pushNamed(context, '/examples')),
            CustomToolbarButton(icon: Icons.settings_outlined, onTap: onSettings),
          ],
        ),
      ),
    );
  }
}
