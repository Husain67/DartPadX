import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/app_state.dart';
import '../../core/theme/app_theme.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final files = editorState.files;
    final activeId = editorState.activeFileId;

    return Container(
      height: 40,
      color: AppTheme.appBarColor,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return GestureDetector(
            onTap: () {
              ref.read(editorProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.backgroundStart : Colors.transparent,
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
                      color: isActive ? Colors.white : Colors.white60,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref.read(editorProvider.notifier).closeFile(file.id);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isActive ? Colors.white : Colors.white60,
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
