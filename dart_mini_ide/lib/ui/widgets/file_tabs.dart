import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final files = fileState.files;
    final activeId = fileState.activeFileId;

    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return InkWell(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF252525) : Colors.transparent,
                border: Border(
                  right: const BorderSide(color: Colors.white10),
                  bottom: isActive ? const BorderSide(color: AppTheme.accentYellow, width: 2) : BorderSide.none,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.accentYellow : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                         _deleteFile(context, ref);
                      },
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Close File?"),
          content: const Text("This will delete the file from storage."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
              child: const Text("Close"),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        ref.read(fileProvider.notifier).deleteActiveFile();
      }
  }
}
