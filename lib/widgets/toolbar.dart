import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Toolbar extends ConsumerWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildButton('New File', Icons.insert_drive_file_outlined, onNewFile),
          _buildButton('Import .dart', Icons.download_outlined, onImport),
          _buildButton('Copy code', Icons.copy_outlined, onCopy),
          _buildButton('Paste', Icons.paste_outlined, onPaste),
          _buildButton('Download .dart', Icons.file_download_outlined, onDownload),
          _buildButton('Share', Icons.share_outlined, onShare),
          _buildButton('Delete current file', Icons.delete_outline, onDelete, isDestructive: true),
          _buildButton('Settings', Icons.settings_outlined, onSettings),
        ],
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onPressed, {bool isDestructive = false}) {
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
              color: isDestructive ? Colors.red.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDestructive ? Colors.red : Colors.grey.shade300,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
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
        ),
      ),
    );
  }
}
