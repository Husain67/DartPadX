import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/files_provider.dart';
import '../../core/theme/app_theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(filesProvider);

    return Container(
      height: 40,
      color: AppTheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filesState.files.length,
        itemBuilder: (context, index) {
          final file = filesState.files[index];
          final isActive = file.id == filesState.activeFileId;

          return GestureDetector(
            onTap: () => ref.read(filesProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.background : AppTheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (isActive) {
                        ref.read(filesProvider.notifier).deleteActiveFile();
                      } else {
                        // We only support deleting active file currently based on provider logic.
                        ref.read(filesProvider.notifier).setActiveFile(file.id);
                        ref.read(filesProvider.notifier).deleteActiveFile();
                      }
                    },
                    child: Icon(Icons.close, size: 16, color: isActive ? AppTheme.primary : AppTheme.textSecondary),
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
