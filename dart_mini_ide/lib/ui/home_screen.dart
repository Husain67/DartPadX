import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../utils/constants.dart';
import 'widgets/toolbar_widget.dart';
import 'editor_widget.dart';
import 'console_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final compilerNotifier = ref.read(compilerProvider.notifier);
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: compilerState.isLoading ? null : () {
                  final code = fileState.activeFile?.content ?? '';
                  compilerNotifier.runCode(code, '');
                },
                icon: compilerState.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                label: const Text("Run", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
              // Toolbar
              const ToolbarWidget(),
              // File Tabs
              Container(
                height: 40,
                color: const Color(0xFF121212),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (context, index) {
                    final file = fileState.files[index];
                    final isActive = index == fileState.activeIndex;
                    return InkWell(
                      onTap: () => ref.read(fileProvider.notifier).setActiveFile(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.surface : Colors.transparent,
                          border: Border(
                            top: isActive ? const BorderSide(color: AppColors.primaryAccent, width: 2) : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              file.name,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white54,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _confirmClose(context, ref, index),
                                child: const Icon(Icons.close, size: 14, color: Colors.white54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Editor
              const Expanded(
                child: EditorWidget(),
              ),
              // Spacer for Console Sheet handle visibility when collapsed
              const SizedBox(height: 50),
            ],
          ),
          // Console Sheet
          const ConsoleSheet(),
        ],
      ),
      ),
    );
  }

  void _confirmClose(BuildContext context, WidgetRef ref, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close File?'),
        content: const Text('Are you sure you want to close/delete this file?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(index);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
