import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../utils/constants.dart';

class FileTabsWidget extends ConsumerWidget {
  const FileTabsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: Colors.black,
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
              decoration: BoxDecoration(
                color: isActive ? AppColors.editorBg : Colors.black,
                border: isActive
                    ? const Border(top: BorderSide(color: AppColors.accentYellow, width: 2))
                    : const Border(bottom: BorderSide(color: Colors.white12, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 14, color: isActive ? AppColors.accentYellow : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(fileProvider.notifier).deleteFile(file.id);
                    },
                    child: Icon(Icons.close, size: 14, color: isActive ? Colors.white70 : Colors.grey),
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
