// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/editor_file.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_panel.dart';
import '../services/execution_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  void _createNewFile() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newFile = EditorFile(
      id: id,
      name: 'untitled_\${id.substring(id.length - 4)}.dart',
      content: 'void main() {\n  \n}',
    );
    ref.read(fileProvider.notifier).addFile(newFile);
  }


  void _copyToClipboard() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Clipboard.setData(ClipboardData(text: activeFile.content));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _pasteFromClipboard() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        ref.read(fileProvider.notifier).updateActiveFileContent(activeFile.content + (data!.text!));
      }
    }
  }

  void _shareCode() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      Share.share(activeFile.content, subject: activeFile.name);
    }
  }

  void _downloadCode() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${activeFile.name}');
      await file.writeAsString(activeFile.content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  void _importCode() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dart', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final newFile = EditorFile(
          id: id,
          name: result.files.single.name,
          content: content,
        );
        ref.read(fileProvider.notifier).addFile(newFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing file: $e')));
      }
    }
  }

  void _deleteCurrentFile() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete File', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Delete this file? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileProvider.notifier).deleteFile(activeFile.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File deleted'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final isRunning = ref.watch(executionProvider.select((s) => s.isRunning));

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            children: [
              const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFACC15), width: 1),
                ),
                child: const Text(
                  'beta',
                  style: TextStyle(color: Color(0xFFFACC15), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: isRunning
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFFFACC15),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () async {
                        final fileNotifier = ref.read(fileProvider.notifier);
                        final activeFile = fileNotifier.activeFile;
                        if (activeFile == null) return;

                        final compilerState = ref.read(compilerProvider);
                        final preset = compilerState.activePreset;
                        if (preset == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No compiler preset selected')));
                          return;
                        }

                        ref.read(executionProvider.notifier).setRunning(true);

                        // Assuming you have imported execution_service
                        final result = await ExecutionService.executeCode(
                          preset: preset,
                          code: activeFile.content,
                          stdinStr: ref.read(stdinProvider),
                        );

                        ref.read(executionProvider.notifier).setResult(
                          stdout: result['stdout'],
                          stderr: result['stderr'],
                          error: result['error'],
                          time: result['time'],
                          memory: result['memory'],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFACC15),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            )
          ],
        ),
        body: Column(
          children: [
            _buildToolbar(),
            _buildTabBar(fileState),
            Expanded(
              child: Stack(
                children: [
                  const CodeEditorWidget(),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: OutputPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _ToolbarButton(icon: Icons.add, label: 'New File', onTap: _createNewFile),
          _ToolbarButton(icon: Icons.download_rounded, label: 'Import', onTap: _importCode),
          _ToolbarButton(icon: Icons.copy, label: 'Copy', onTap: _copyToClipboard),
          _ToolbarButton(icon: Icons.paste, label: 'Paste', onTap: _pasteFromClipboard),
          _ToolbarButton(icon: Icons.file_download, label: 'Download', onTap: _downloadCode),
          _ToolbarButton(icon: Icons.share, label: 'Share', onTap: _shareCode),
          _ToolbarButton(icon: Icons.delete_outline, label: 'Delete', onTap: _deleteCurrentFile, isDestructive: true),
          _ToolbarButton(icon: Icons.settings, label: 'Settings', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildTabBar(FileState state) {
    if (state.files.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: Colors.black,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          final isActive = file.id == state.activeFileId;

          return GestureDetector(
            onTap: () {
              ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isDestructive ? Colors.red : Colors.black87),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
