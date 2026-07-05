import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/file_provider.dart';

class TabBarWidget extends ConsumerWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 40,
      color: AppTheme.backgroundDark,
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
                color: isActive ? AppTheme.backgroundLight : AppTheme.backgroundDark,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                  right: BorderSide(
                    color: AppTheme.textMuted.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: isActive ? AppTheme.primaryAccent : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppTheme.textLight : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (fileState.files.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Prevent modifying state synchronously during build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           final currentActive = ref.read(fileProvider).activeFileId;
                           if (currentActive == file.id) {
                               ref.read(fileProvider.notifier).deleteActiveFile();
                           } else {
                               // Quick and dirty deletion of non-active tabs.
                               final prevActive = currentActive;
                               ref.read(fileProvider.notifier).setActiveFile(file.id);
                               ref.read(fileProvider.notifier).deleteActiveFile();
                               if (prevActive != null) {
                                  ref.read(fileProvider.notifier).setActiveFile(prevActive);
                               }
                           }
                        });
                      },
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.textMuted.withOpacity(0.5),
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
