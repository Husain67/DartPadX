import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';
import '../../models/code_file.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return Container(
      height: 48,
      color: Colors.black,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isSelected = file == fileState.currentFile;

          return Material(
            color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: InkWell(
              onTap: () => ref.read(fileProvider.notifier).selectFile(file),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(top: BorderSide(color: Color(0xFFFACC15), width: 2))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                           // Logic to close/delete file
                           // If current, use deleteCurrentFile logic but confirm first?
                           // Prompt said "Click -> beautiful confirmation dialog" for DELETE button.
                           // For tabs "closable with X", usually means close view or delete file?
                           // In simple editor "Close" often means just close view if saved, or delete if unsaved?
                           // Here files are auto-saved to Hive.
                           // So "Close" means "Remove from list but keep in Hive"? Or "Delete"?
                           // Since we don't have "Open File" explorer (only Import),
                           // maybe "Close" means hide from tabs?
                           // But `fileProvider` manages open files as `state.files`.
                           // If we remove from `state.files`, how do we open it again?
                           // We load ALL files from Hive on start.
                           // So `state.files` == All Hive files.
                           // So "Close" == "Delete"?
                           // Or "Close" == "Hide"? If we hide, we can't reopen easily without a file explorer.
                           // Given "Delete current file" is a separate feature, "Close with X" implies closing the tab.
                           // But if tabs == all files, then closing tab == hiding file?
                           // Let's assume closing tab == deleting file for now, or just deleting from view?
                           // Without a file explorer, deleting from view makes it inaccessible.
                           // So I will make "X" show the delete confirmation dialog.

                           showDialog(
                             context: context,
                             builder: (ctx) => AlertDialog(
                               backgroundColor: const Color(0xFF1A1A1A),
                               title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
                               content: Text(
                                 'Delete ${file.name} permanently?',
                                 style: const TextStyle(color: Colors.white70),
                               ),
                               actions: [
                                 TextButton(
                                   onPressed: () => Navigator.pop(ctx),
                                   child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                 ),
                                 TextButton(
                                   onPressed: () {
                                     ref.read(fileProvider.notifier).deleteFile(file);
                                     Navigator.pop(ctx);
                                   },
                                   child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                 ),
                               ],
                             ),
                           );
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
