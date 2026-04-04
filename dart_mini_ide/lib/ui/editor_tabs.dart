import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/file_provider.dart';

class EditorTabs extends ConsumerWidget {
  const EditorTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: AppTheme.bgDark,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;

          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.bgLight : AppTheme.bgDark,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.accentYellow : Colors.transparent,
                    width: 2,
                  ),
                  right: const BorderSide(color: Color(0xFF222222), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fileState.files.length > 1)
                    GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).deleteFileById(file.id),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white70 : AppTheme.textSecondary,
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
