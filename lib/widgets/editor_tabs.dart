import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';
import '../utils/ui_utils.dart';

class EditorTabs extends ConsumerWidget {
  const EditorTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final files = fileState.files;
    final activeId = fileState.activeFileId;

    return Container(
      height: 40,
      color: AppTheme.surfaceColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).switchFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? Colors.black26 : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryYellow : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white60,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final confirm = await UiUtils.showConfirmDialog(
                        context,
                        title: 'Close File',
                        content: 'Delete this file? This cannot be undone.',
                        isDestructive: true,
                        confirmText: 'Close & Delete',
                      );
                      if (confirm == true) {
                        ref.read(fileProvider.notifier).deleteFile(file.id);
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isActive ? Colors.white : Colors.white60,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
