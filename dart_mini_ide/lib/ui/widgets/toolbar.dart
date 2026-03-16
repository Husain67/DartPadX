import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ToolbarWidget extends ConsumerWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;
  final VoidCallback onFormat;

  const ToolbarWidget({
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolbarButton('New', Icons.note_add, onNewFile),
          _buildToolbarButton('Import', Icons.file_download, onImport),
          _buildToolbarButton('Copy', Icons.copy, onCopy),
          _buildToolbarButton('Paste', Icons.paste, onPaste),
          _buildToolbarButton('Download', Icons.download, onDownload),
          _buildToolbarButton('Share', Icons.share, onShare),
          _buildToolbarButton('Delete', Icons.delete, onDelete),
          _buildToolbarButton('Format', Icons.format_align_left, onFormat),
          _buildToolbarButton('Settings', Icons.settings, onSettings),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9F9F9),
          foregroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
