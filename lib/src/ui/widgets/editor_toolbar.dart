import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class EditorToolbar extends ConsumerWidget {
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
    Key? key,
    required this.onNewFile,
    required this.onImport,
    required this.onCopy,
    required this.onPaste,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.onSettings,
    required this.onFormat,
  }) : super(key: key);

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            height: 48, // EXACT TOUCH TARGET SIZE
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.toolbarBg, // white/cream
              borderRadius: BorderRadius.circular(24), // pill shape
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.textDark, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textDark,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          _buildToolbarButton(icon: Icons.add, label: 'New File', onPressed: onNewFile),
          _buildToolbarButton(icon: Icons.file_download, label: 'Import', onPressed: onImport),
          _buildToolbarButton(icon: Icons.copy, label: 'Copy', onPressed: onCopy),
          _buildToolbarButton(icon: Icons.paste, label: 'Paste', onPressed: onPaste),
          _buildToolbarButton(icon: Icons.download, label: 'Download', onPressed: onDownload),
          _buildToolbarButton(icon: Icons.share, label: 'Share', onPressed: onShare),
          _buildToolbarButton(icon: Icons.format_align_left, label: 'Format', onPressed: onFormat),
          _buildToolbarButton(icon: Icons.delete_outline, label: 'Delete', onPressed: onDelete),
          _buildToolbarButton(icon: Icons.settings, label: 'Settings', onPressed: onSettings),
        ],
      ),
    );
  }
}
