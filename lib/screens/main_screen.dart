import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: AppTheme.appbarBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: executionState.isRunning
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).executeCode();
                    },
              icon: executionState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.appbarBlack),
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFileTabs(context, ref, fileState),
              const ToolbarWidget(),
              const Expanded(child: EditorWidget()),
              // Padding to allow scrolling editor past output sheet handle
              const SizedBox(height: 40),
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Widget _buildFileTabs(BuildContext context, WidgetRef ref, FileState fileState) {
    if (fileState.files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: AppTheme.surfaceBlack,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isSelected = file.id == fileState.currentFileId;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).switchFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.backgroundBlack : Colors.transparent,
                border: Border(
                  top: BorderSide(
                    color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                  right: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primaryAccent : AppTheme.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Allow deleting from tab if it's not the only file,
                          // but the toolbar already has delete button.
                        },
                        child: const Icon(Icons.close, size: 14, color: AppTheme.textMuted),
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
