import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  final CodeController controller;

  const EditorWidget({super.key, required this.controller});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesProvider);
    final activeFileId = ref.watch(activeFileIdProvider);

    return Column(
      children: [
        _buildTabs(files, activeFileId),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: widget.controller,
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(List<dynamic> files, String? activeId) {
    return Container(
      height: 40,
      color: const Color(0xFF0D0D0D),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          final isActive = file.id == activeId;

          return GestureDetector(
            onTap: () {
              ref.read(activeFileIdProvider.notifier).setActive(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1A1A1A) : Colors.transparent,
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
                      color: isActive ? const Color(0xFFFACC15) : Colors.white70,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (files.length > 1) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        ref.read(filesProvider.notifier).deleteFile(file.id);
                        if (isActive && files.length > 1) {
                          final nextFile = files.firstWhere((f) => f.id != file.id);
                          ref.read(activeFileIdProvider.notifier).setActive(nextFile.id);
                        }
                      },
                      child: const Icon(Icons.close, size: 16, color: Colors.white54),
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
