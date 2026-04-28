import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Material(
        color: AppTheme.toolbarButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.toolbarButtonBorder, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
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

class Toolbar extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;
  final VoidCallback onFormat;

  const Toolbar({
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          ToolbarButton(icon: Icons.add, label: 'New File', onTap: onNewFile),
          ToolbarButton(icon: Icons.file_download, label: 'Import .dart', onTap: onImport),
          ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: onCopy),
          ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: onPaste),
          ToolbarButton(icon: Icons.auto_awesome, label: 'Format', onTap: onFormat),
          ToolbarButton(icon: Icons.download, label: 'Download', onTap: onDownload),
          ToolbarButton(icon: Icons.share, label: 'Share', onTap: onShare),
          ToolbarButton(icon: Icons.delete_outline, label: 'Delete', onTap: onDelete),
          ToolbarButton(icon: Icons.settings_outlined, label: 'Settings', onTap: onSettings),
        ],
      ),
    );
  }
}
