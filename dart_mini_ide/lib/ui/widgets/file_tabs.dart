import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileProvider);
    final currentIndex = ref.watch(currentFileIndexProvider);

    return Container(
      height: 48,
      color: const Color(0xFF0F0F0F),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isSelected = index == currentIndex;
          return InkWell(
            onTap: () {
              ref.read(currentFileIndexProvider.notifier).state = index;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
                border: isSelected
                    ? const Border(bottom: BorderSide(color: Color(0xFFFACC15), width: 2))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _closeFile(context, ref, index);
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _closeFile(BuildContext context, WidgetRef ref, int index) {
    // Logic to close/delete file.
    // If it's just closing a tab but keeping file, that's different.
    // But requirement said "Delete current file" in toolbar.
    // Tabs usually mean "open files".
    // Since we persist all files in Hive as "project files", closing a tab might mean removing it from view?
    // But "Delete" is separate.
    // Let's assume "Close" on tab means "Close from view" but keep in project?
    // But my FileProvider lists ALL files in Hive.
    // So "Close" here effectively means "Delete" if we don't have a concept of "Open vs Project".
    // Given mobile context, usually "Tabs" are just the files.
    // So clicking X might invoke Delete or "Close".
    // If I delete, it's destructive.
    // I'll make it show the Delete confirmation dialog same as toolbar.

    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
      content: Text('Delete ${ref.read(fileProvider)[index].name}?', style: const TextStyle(color: Colors.grey)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () {
           // Handle index shift
           final current = ref.read(currentFileIndexProvider);
           ref.read(fileProvider.notifier).deleteFile(index).then((_) {
               // Files list updates automatically via provider watch in next build?
               // But we need to update currentIndex if it became invalid.
               // We can do it here.
               final count = ref.read(fileProvider).length;
               if (current >= count) {
                   ref.read(currentFileIndexProvider.notifier).state = count > 0 ? count - 1 : 0;
               } else if (index < current) {
                   ref.read(currentFileIndexProvider.notifier).state = current - 1;
               }
               // If we closed the current one (index == current), we fall through to same index (which is next file), unless it was last.
           });
           Navigator.pop(context);
        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}
