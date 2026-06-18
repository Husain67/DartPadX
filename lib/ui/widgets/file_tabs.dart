import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../core/theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: AppTheme.pureBlack,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: state.files.map((file) {
            final isActive = file.id == state.activeFileId;
            return GestureDetector(
              onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.surfaceColor : AppTheme.pureBlack,
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
