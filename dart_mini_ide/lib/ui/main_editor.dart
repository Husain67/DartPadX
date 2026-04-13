import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import '../providers/file_provider.dart';
import '../providers/preset_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import '../utils/editor_actions.dart';
import 'examples_sheet.dart';
import 'output_sheet.dart';
import 'settings/settings_screen.dart';

class MainEditorScreen extends ConsumerStatefulWidget {
  const MainEditorScreen({super.key});

  @override
  ConsumerState<MainEditorScreen> createState() => _MainEditorScreenState();
}

class _MainEditorScreenState extends ConsumerState<MainEditorScreen> {
  late CodeController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _runCode() {
    final fileState = ref.read(fileProvider);
    if (fileState.activeFile == null) return;

    final settings = ref.read(settingsProvider);
    final presets = ref.read(presetProvider).presets;

    var preset = presets.firstWhere(
      (p) => p.name == 'OneCompiler',
      orElse: () => presets.first,
    );

    if (!settings.useDefaultOneCompiler && settings.activeCustomPresetId != null) {
      preset = presets.firstWhere(
        (p) => p.id == settings.activeCustomPresetId,
        orElse: () => preset,
      );
    }

    ref.read(executionProvider.notifier).executeCode(
      code: fileState.activeFile!.content,
      stdin: '', // Can be extended to have a stdin input field later
      preset: preset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

    // Sync controller
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId && next.activeFile != null) {
        if (_codeController.text != next.activeFile!.content) {
          _codeController.text = next.activeFile!.content;
        }
      }
    });

    // Initial sync
    if (_codeController.text.isEmpty && fileState.activeFile != null && fileState.activeFile!.content.isNotEmpty) {
      _codeController.text = fileState.activeFile!.content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(execState),
              _buildToolbar(context, fileState),
              _buildFileTabs(fileState),
              Expanded(
                child: Stack(
                  children: [
                    _buildEditor(),
                    const OutputSheet(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(ExecutionState execState) {
    return Container(
      height: 56,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'DartMini',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFACC15).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFACC15)),
            ),
            child: const Text(
              'beta',
              style: TextStyle(
                color: Color(0xFFFACC15),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: execState.isExecuting ? null : _runCode,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (execState.isExecuting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  else
                    const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    'Run',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, FileState fileState) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ToolbarBtn(icon: Icons.add, label: 'New', onTap: () => EditorActions.newFile(ref)),
          _ToolbarBtn(icon: Icons.library_books, label: 'Examples', onTap: () { showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const ExamplesSheet()); }),
          _ToolbarBtn(icon: Icons.download_rounded, label: 'Import', onTap: () => EditorActions.importFile(ref)),
          _ToolbarBtn(icon: Icons.copy, label: 'Copy', onTap: () => EditorActions.copyCode(fileState.activeFile?.content)),
          _ToolbarBtn(icon: Icons.paste, label: 'Paste', onTap: () => EditorActions.pasteCode(_codeController)),
          _ToolbarBtn(icon: Icons.format_align_left, label: 'Format', onTap: () => EditorActions.formatCode(_codeController)),
          _ToolbarBtn(icon: Icons.file_download, label: 'Download', onTap: () => EditorActions.downloadFile(fileState.activeFile)),
          _ToolbarBtn(icon: Icons.share, label: 'Share', onTap: () => EditorActions.shareFile(fileState.activeFile)),
          _ToolbarBtn(icon: Icons.delete_outline, label: 'Delete', onTap: () => EditorActions.deleteFile(context, ref, fileState.activeFileId)),
          _ToolbarBtn(icon: Icons.settings, label: 'Settings', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildFileTabs(FileState fileState) {
    return Container(
      height: 40,
      color: Colors.black26,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () => ref.read(fileProvider.notifier).setActiveFile(file.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2A2A2A) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
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
                      color: isActive ? Colors.white : Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.white70 : Colors.white30,
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

  Widget _buildEditor() {
    return CodeTheme(
      data: CodeThemeData(styles: atomOneDarkTheme),
      child: SingleChildScrollView(
        child: CodeField(
          controller: _codeController,
          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          gutterStyle: const GutterStyle(
            textStyle: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
            showLineNumbers: true,
          ),
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
