import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';

import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import 'widgets/toolbar.dart';
import 'widgets/output_sheet.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  CodeController? _codeController;
  String _currentFileId = '';
  bool _isControllerSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCodeController();
    });
  }

  void _initCodeController() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      _currentFileId = activeFile.id;
      _codeController = CodeController(
        text: activeFile.content,
        language: dart,
      );
      _codeController!.addListener(_onCodeChanged);
      setState(() {});
    }
  }

  void _onCodeChanged() {
    if (_codeController != null && !_isControllerSyncing) {
      ref.read(fileProvider.notifier).updateFileContent(_currentFileId, _codeController!.text);
    }
  }

  @override
  void dispose() {
    _codeController?.removeListener(_onCodeChanged);
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active file changes to update the code controller safely
    ref.listen<String?>(
      fileProvider.select((state) => state.activeFileId),
      (previous, next) {
        if (next != null && next != _currentFileId) {
          _currentFileId = next;
          final file = ref.read(fileProvider.notifier).activeFile;
          if (file != null && _codeController != null) {
            _isControllerSyncing = true;
            _codeController!.text = file.content;
            _isControllerSyncing = false;
          }
        }
      },
    );

    // Also listen to external content updates (like paste) that might update the Riverpod state directly
    ref.listen<String?>(
      fileProvider.select((state) {
        if (state.activeFileId == null) return null;
        try {
          return state.files.firstWhere((f) => f.id == state.activeFileId).content;
        } catch (_) {
          return null;
        }
      }),
      (previousContent, nextContent) {
        if (nextContent != null && _codeController != null && _codeController!.text != nextContent && !_isControllerSyncing) {
          _isControllerSyncing = true;
          // preserve selection if possible, though setting text resets it
          _codeController!.text = nextContent;
          _isControllerSyncing = false;
        }
      },
    );

    final fileState = ref.watch(fileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _buildRunButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            if (_codeController != null)
              EditorToolbar(codeController: _codeController!),
            _buildFileTabs(fileState),
            Expanded(
              child: _codeController == null
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
                  : CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController!,
                          gutterStyle: GutterStyle(
                            textStyle: const TextStyle(color: Colors.grey),
                            background: Colors.black.withValues(alpha: 0.2),
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: const OutputSheet(),
    );
  }

  Widget _buildRunButton() {
    final execState = ref.watch(executionProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: execState.isRunning
            ? null
            : () {
                if (_codeController != null) {
                  ref.read(executionProvider.notifier).runCode(_codeController!.text);
                }
              },
        icon: execState.isRunning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Icon(Icons.play_arrow, color: Colors.black),
        label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTabs(FileState fileState) {
    return Container(
      height: 40,
      color: Colors.black.withValues(alpha: 0.5),
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
                color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
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
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmation(file.id);
                    },
                    child: Icon(
                      Icons.close,
                      size: 16,
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

  void _showDeleteConfirmation(String fileId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File'),
          content: const Text('Delete this file? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(fileProvider.notifier).deleteFile(fileId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File deleted'), backgroundColor: Colors.red),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
