import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../theme/app_theme.dart';

class FileTabsWidget extends ConsumerWidget {
  const FileTabsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final files = fileState.files;
    final activeId = fileState.activeFileId;

    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundStart,
        border: Border(bottom: BorderSide(color: AppTheme.backgroundEnd, width: 2)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundEnd : AppTheme.backgroundStart,
                border: isActive
                    ? const Border(
                        bottom: BorderSide(color: AppTheme.primaryAccent, width: 2),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(fileProvider.notifier).deleteFile(file.id);
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isActive ? Colors.white70 : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
