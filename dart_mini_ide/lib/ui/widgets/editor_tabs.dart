import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/file_provider.dart';

class EditorTabs extends ConsumerWidget {
  const EditorTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final files = fileState.files;
    final currentId = fileState.currentFileId;

    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.backgroundStart,
        border: Border(bottom: BorderSide(color: AppColors.buttonBorder, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isSelected = file.id == currentId;

          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).selectFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.backgroundEnd : AppColors.backgroundStart,
                border: Border(
                  right: const BorderSide(color: AppColors.buttonBorder, width: 1),
                  bottom: BorderSide(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (files.length > 1) {
                         ref.read(fileProvider.notifier).deleteFileById(file.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
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
