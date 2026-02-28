import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class FileTabsWidget extends ConsumerWidget {
  const FileTabsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              margin: const EdgeInsets.only(right: 2, top: 4),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundEnd : Colors.black45,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border(
                  top: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name + (file.isSaved ? '' : '*'),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textMuted,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (fileState.files.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Close logic - simplified to just act as a wrapper for delete
                        // in a full IDE this might just remove from view, but here
                        // we'll set a different file as active or if active, switch.
                        // We will just call a simple switch logic.
                        if (isActive) {
                           int newIndex = index == 0 ? 1 : 0;
                           ref.read(fileProvider.notifier).setActiveFile(fileState.files[newIndex].id);
                        }
                      },
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white70 : AppTheme.textMuted,
                      ),
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
}
