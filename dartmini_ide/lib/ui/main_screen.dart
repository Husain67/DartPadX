import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import 'editor_widget.dart';
import 'toolbar_widget.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(filesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              const ToolbarWidget(),
              _buildTabs(ref, fileState),
              const Expanded(
                child: Stack(
                  children: [
                    EditorWidget(),
                    OutputSheet(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'DartMini',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              final activeFile = ref.read(filesProvider).activeFile;
              if (activeFile != null) {
                final settings = ref.read(compilerSettingsProvider);
                ref.read(executionProvider.notifier).executeCode(activeFile.content, settings);
              }
            },
            icon: const Icon(Icons.play_arrow, color: Colors.black),
            label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref, FileState state) {
    if (state.files.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 40,
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = index == state.activeIndex;
          return GestureDetector(
            onTap: () => ref.read(filesProvider.notifier).setActiveIndex(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2B2B2B) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    file.name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (isActive) {
                         ref.read(filesProvider.notifier).removeActiveFile();
                      }
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.white : Colors.grey,
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
