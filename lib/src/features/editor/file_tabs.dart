import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/files_provider.dart';
import '../../theme/app_theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesState = ref.watch(filesProvider);

    return Container(
      height: 40,
      color: AppTheme.lighterBackground,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filesState.files.length,
        itemBuilder: (context, index) {
          final file = filesState.files[index];
          final isActive = file.id == filesState.activeFileId;

          return GestureDetector(
            onTap: () {
               ref.read(filesProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.surfaceColor : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.accentYellow : Colors.transparent,
                    width: 2,
                  ),
                  right: const BorderSide(color: Colors.black26, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 14,
                    color: isActive ? AppTheme.accentYellow : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                       ref.read(filesProvider.notifier).deleteFile(file.id);
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.white70 : Colors.grey,
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
