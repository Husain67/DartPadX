import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../theme.dart';

class EditorTabs extends ConsumerWidget {
  const EditorTabs({super.key});

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
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.darkSurface : Colors.black,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.accentYellow : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.accentYellow : AppTheme.textDim,
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (fileState.files.length > 1) // don't close if only 1
                    GestureDetector(
                      onTap: () {
                         ref.read(fileProvider.notifier).setActiveFile(file.id);
                         ref.read(fileProvider.notifier).deleteActiveFile();
                      },
                      child: const Icon(Icons.close, size: 14, color: AppTheme.textDim),
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
