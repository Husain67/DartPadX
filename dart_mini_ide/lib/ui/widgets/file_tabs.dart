import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundEnd,
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = fileState.activeFile?.id == file.id;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryAccent.withOpacity(0.1) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    size: 16,
                    color: isActive ? AppTheme.primaryAccent : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryAccent : Colors.white70,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive)
                    GestureDetector(
                      onTap: () {
                         ref.read(fileProvider.notifier).deleteFile(file);
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.close, size: 16, color: Colors.white54),
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
