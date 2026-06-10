import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EditorToolbar extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onGallery;
  final VoidCallback onSettings;
  final VoidCallback onFormat;
  final VoidCallback onClearOutput;

  const EditorToolbar({
    super.key,
    required this.onNewFile,
    required this.onImport,
    required this.onCopy,
    required this.onPaste,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.onGallery,
    required this.onSettings,
    required this.onFormat,
    required this.onClearOutput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton(Icons.add, 'New File', onNewFile),
          _buildButton(Icons.photo_library, 'Gallery', onGallery),
          _buildButton(Icons.download_rounded, 'Import', onImport),
          _buildButton(Icons.copy, 'Copy', onCopy),
          _buildButton(Icons.paste, 'Paste', onPaste),
          _buildButton(Icons.file_download, 'Download', onDownload),
          _buildButton(Icons.share, 'Share', onShare),
          _buildButton(Icons.delete, 'Delete', onDelete, isDestructive: true),
          _buildButton(Icons.format_align_left, 'Format', onFormat),
          _buildButton(Icons.clear_all, 'Clear', onClearOutput),
          _buildButton(Icons.settings, 'Settings', onSettings),
        ],
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, VoidCallback onPressed, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDestructive ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isDestructive ? Colors.redAccent : Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? Colors.redAccent : Colors.white,
                    fontWeight: FontWeight.w500,
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
