import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppToolbar extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;
  final VoidCallback onFormat;

  const AppToolbar({
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolbarButton('New File', Icons.insert_drive_file_outlined, onNewFile),
            const SizedBox(width: 8),
            _buildToolbarButton('Import', Icons.file_download_outlined, onImport),
            const SizedBox(width: 8),
            _buildToolbarButton('Copy', Icons.copy, onCopy),
            const SizedBox(width: 8),
            _buildToolbarButton('Paste', Icons.paste, onPaste),
            const SizedBox(width: 8),
            _buildToolbarButton('Download', Icons.download, onDownload),
            const SizedBox(width: 8),
            _buildToolbarButton('Share', Icons.share, onShare),
            const SizedBox(width: 8),
            _buildToolbarButton('Delete', Icons.delete_outline, onDelete, isDestructive: true),
            const SizedBox(width: 8),
            _buildToolbarButton('Format', Icons.format_align_left, onFormat),
            const SizedBox(width: 8),
            _buildToolbarButton('Settings', Icons.settings, onSettings),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.toolbarButtonBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.toolbarButtonBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
