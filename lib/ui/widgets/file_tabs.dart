import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/providers/file_provider.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: Colors.black26,
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
                color: isActive ? AppTheme.bgLightDark : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (fileState.files.length > 1) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        // Switch active file then delete to avoid issues
                        ref.read(fileProvider.notifier).setActiveFile(file.id);
                        ref.read(fileProvider.notifier).deleteActiveFile();
                      },
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white : Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
