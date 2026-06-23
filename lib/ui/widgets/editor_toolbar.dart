import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'toolbar_button.dart';
import '../../providers/file_provider.dart';
import 'examples_sheet.dart';

class EditorToolbar extends ConsumerWidget {
  final VoidCallback onNewFile;
  final VoidCallback onImport;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onSettings;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        children: [
          ToolbarButton(icon: Icons.note_add, label: 'New File', onTap: onNewFile),
          ToolbarButton(icon: Icons.file_download_outlined, label: 'Import .dart', onTap: onImport),
          ToolbarButton(
            icon: Icons.auto_awesome,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formattedCode = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion).format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formattedCode);
                } catch (e) {
                  // Ignore parse errors if unformattable
                }
              }
            },
          ),
          ToolbarButton(
            icon: Icons.library_books,
            label: 'Examples',
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const ExamplesSheet(),
              );
            },
          ),
          ToolbarButton(icon: Icons.copy, label: 'Copy code', onTap: onCopy),
          ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: onPaste),
          ToolbarButton(icon: Icons.download_rounded, label: 'Download .dart', onTap: onDownload),
          ToolbarButton(icon: Icons.share, label: 'Share', onTap: onShare),
          ToolbarButton(icon: Icons.delete_outline, label: 'Delete', onTap: onDelete),
          ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: onSettings),
        ],
      ),
    );
  }
}
