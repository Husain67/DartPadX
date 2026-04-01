import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/file_provider.dart';
import '../utils/colors.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 48,
      color: AppColors.backgroundStart,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.tabActive : AppColors.tabInactive,
                border: isActive
                    ? const Border(
                        top: BorderSide(color: AppColors.accentYellow, width: 2),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 16,
                    color: isActive ? AppColors.accentYellow : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          // Prevent closing the last file directly from the tab
                          if (fileState.files.length > 1) {
                            ref.read(fileProvider.notifier).deleteFile(file.id);
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cannot close the last open file.')),
                             );
                          }
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
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