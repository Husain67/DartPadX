import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';

class FileTabsWidget extends ConsumerWidget {
  const FileTabsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: AppTheme.backgroundStart,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;

          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).switchFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundEnd : AppTheme.backgroundStart,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryYellow : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive && fileState.files.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).deleteActiveFile(),
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
}
