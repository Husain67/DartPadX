import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ToolbarButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const ToolbarButton({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.toolbarItemBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18, color: Colors.black87)),
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
  final VoidCallback onExamples;

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
    required this.onExamples,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ToolbarButton(label: 'New File', icon: '📄', onTap: onNewFile),
          ToolbarButton(label: 'Import', icon: '📥', onTap: onImport),
          ToolbarButton(label: 'Copy', icon: '📋', onTap: onCopy),
          ToolbarButton(label: 'Paste', icon: '📝', onTap: onPaste),
          ToolbarButton(label: 'Download', icon: '⬇️', onTap: onDownload),
          ToolbarButton(label: 'Share', icon: '🔗', onTap: onShare),
          ToolbarButton(label: 'Delete', icon: '🗑️', onTap: onDelete),
          ToolbarButton(label: 'Examples', icon: '💡', onTap: onExamples),
          ToolbarButton(label: 'Settings', icon: '⚙️', onTap: onSettings),
        ],
      ),
    );
  }
}
