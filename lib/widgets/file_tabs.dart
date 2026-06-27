import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';

class FileTabs extends ConsumerWidget {
  const FileTabs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(fileProvider);
    final activeId = ref.watch(currentFileIdProvider);

    if (files.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return GestureDetector(
            onTap: () {
              ref.read(currentFileIdProvider.notifier).state = file.id;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1a1a1a) : Colors.black,
                border: Border(
                  top: BorderSide(color: isActive ? const Color(0xFFFACC15) : Colors.transparent, width: 2),
                  right: const BorderSide(color: Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (files.length > 1) {
                        ref.read(fileProvider.notifier).deleteFile(file.id);
                        if (isActive) {
                          final newFiles = ref.read(fileProvider);
                          ref.read(currentFileIdProvider.notifier).state = newFiles.first.id;
                        }
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: files.length > 1 ? (isActive ? Colors.white70 : Colors.white38) : Colors.transparent,
                    ),
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
