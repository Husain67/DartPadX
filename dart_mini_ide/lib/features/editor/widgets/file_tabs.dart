import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/features/editor/providers/editor_provider.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return Container(
      height: 40,
      color: Colors.black12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: editorState.files.length,
        itemBuilder: (context, index) {
          final file = editorState.files[index];
          final isActive = file.id == editorState.activeFileId;

          return GestureDetector(
            onTap: () => notifier.setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? AppColors.accent : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                         showDialog(
                           context: context,
                           builder: (c) => AlertDialog(
                             title: const Text('Delete File?'),
                             content: const Text('This cannot be undone.'),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                               TextButton(
                                 onPressed: () {
                                   notifier.deleteFile(file.id);
                                   Navigator.pop(c);
                                   Fluttertoast.showToast(msg: "File deleted");
                                 },
                                 child: const Text('Delete', style: TextStyle(color: Colors.red)),
                               ),
                             ],
                           ),
                         );
                      },
                      child: Icon(Icons.close, size: 16, color: isActive ? AppColors.accent : Colors.grey),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
