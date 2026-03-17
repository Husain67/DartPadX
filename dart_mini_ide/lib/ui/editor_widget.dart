import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/dracula.dart';

import '../providers.dart';
import '../theme.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  CodeController? _controller;
  String? _activeFileId;

  @override
  void initState() {
    super.initState();
    // Initialize controller will be handled in build based on active file
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_activeFileId != null && _controller != null) {
      ref.read(fileProvider.notifier).updateContent(_activeFileId!, _controller!.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);

    // Sync controller with active file
    if (fileState.activeFileId != _activeFileId) {
      if (_activeFileId != null) {
        ref.read(fileProvider.notifier).forceSave(_activeFileId!);
      }
      _activeFileId = fileState.activeFileId;
      final activeFile = ref.read(fileProvider.notifier).activeFile;

      _controller?.removeListener(_onTextChanged);
      _controller?.dispose();

      _controller = CodeController(
        text: activeFile?.content ?? '',
        language: dart,
      );
      _controller!.addListener(_onTextChanged);
    }

    if (fileState.files.isEmpty || _controller == null) {
      return const Center(child: Text('No files open', style: TextStyle(color: AppTheme.textSecondary)));
    }

    return Column(
      children: [
        _buildTabs(fileState),
        Expanded(
          child: Container(
            color: const Color(0xFF282A36), // Dracula background
            child: CodeTheme(
              data: CodeThemeData(styles: draculaTheme),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller!,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  gutterStyle: const GutterStyle(showLineNumbers: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(FileState fileState) {
    return Container(
      height: 40,
      color: AppTheme.backgroundLight,
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
                color: isActive ? const Color(0xFF282A36) : Colors.transparent, // Match editor bg
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
                      color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmation(context, file.id);
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
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

  void _showDeleteConfirmation(BuildContext context, String fileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundLight,
        title: const Text('Delete this file?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This cannot be undone.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(fileId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
