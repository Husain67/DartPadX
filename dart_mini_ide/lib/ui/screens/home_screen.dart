import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_style/dart_style.dart';
import '../../providers/file_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/output_provider.dart';
import '../../services/compiler_service.dart';
import '../../services/file_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  final FileService _fileService = FileService();
  final CompilerService _compilerService = CompilerService();

  void _runCode(WidgetRef ref) async {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    final settings = ref.read(settingsProvider);
    final outputNotifier = ref.read(outputProvider.notifier);

    outputNotifier.setLoading(true);

    final result = await _compilerService.executeCode(
      code: activeFile.content,
      useDefault: settings.useOneCompiler,
      preset: settings.activePreset,
    );

    outputNotifier.setOutput(result);
  }

  void _formatCode(WidgetRef ref) {
    final fileState = ref.read(fileProvider);
    final activeFile = fileState.activeFile;
    if (activeFile == null) return;

    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);
      final formatted = formatter.format(activeFile.content);
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: "Code formatted");
    } catch (e) {
      Fluttertoast.showToast(msg: "Format error: \${e.toString().split('\\n').first}");
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String fileId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(fileProvider.notifier).removeFile(fileId);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: "File deleted");
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileState = ref.watch(fileProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () async {
          final file = fileState.activeFile;
          if (file != null) {
            bool success = await _fileService.saveFileMobile(file.name, file.content);
            Fluttertoast.showToast(msg: success ? "Saved to device" : "Failed to save");
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          ref.read(fileProvider.notifier).addFile('untitled.dart');
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Container(
            decoration: AppTheme.gradientBackground,
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // App Bar
                      Container(
                        height: 56,
                        color: AppTheme.pureBlack,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'beta',
                                style: TextStyle(
                                  color: AppTheme.pureBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () => _runCode(ref),
                              icon: const Icon(Icons.play_arrow, color: AppTheme.pureBlack),
                              label: const Text('Run', style: TextStyle(color: AppTheme.pureBlack, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Toolbar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            _buildToolbarButton(Icons.add, 'New', () {
                              ref.read(fileProvider.notifier).addFile('untitled.dart');
                            }),
                            _buildToolbarButton(Icons.download, 'Import', () async {
                              final content = await _fileService.pickAndReadFile();
                              if (content != null) {
                                ref.read(fileProvider.notifier).addFile('imported.dart', content);
                                Fluttertoast.showToast(msg: "File imported");
                              }
                            }),
                            _buildToolbarButton(Icons.copy, 'Copy', () {
                              final content = fileState.activeFile?.content ?? '';
                              Clipboard.setData(ClipboardData(text: content));
                              Fluttertoast.showToast(msg: "Copied to clipboard");
                            }),
                            _buildToolbarButton(Icons.paste, 'Paste', () async {
                              final data = await Clipboard.getData('text/plain');
                              if (data != null && data.text != null) {
                                 ref.read(fileProvider.notifier).updateActiveFileContent(data.text!);
                                 Fluttertoast.showToast(msg: "Pasted from clipboard");
                              }
                            }),
                            _buildToolbarButton(Icons.save_alt, 'Download', () async {
                              final file = fileState.activeFile;
                              if (file != null) {
                                bool success = await _fileService.saveFileMobile(file.name, file.content);
                                Fluttertoast.showToast(msg: success ? "Saved to device" : "Failed to save");
                              }
                            }),
                            _buildToolbarButton(Icons.share, 'Share', () {
                              final content = fileState.activeFile?.content ?? '';
                              Share.share(content);
                            }),
                            _buildToolbarButton(Icons.format_align_left, 'Format', () {
                              _formatCode(ref);
                            }),
                            _buildToolbarButton(Icons.delete_outline, 'Delete', () {
                              final file = fileState.activeFile;
                              if (file != null) {
                                _confirmDelete(context, ref, file.id);
                              }
                            }),
                            _buildToolbarButton(Icons.settings, 'Settings', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            }),
                          ],
                        ),
                      ),

                      // File Tabs
                      Container(
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.05),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: fileState.files.length,
                          itemBuilder: (context, index) {
                            final file = fileState.files[index];
                            final isActive = file.id == fileState.activeFileId;
                            return GestureDetector(
                              onTap: () {
                                ref.read(fileProvider.notifier).switchFile(file.id);
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
                                        color: isActive ? Colors.white : Colors.white54,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _confirmDelete(context, ref, file.id),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white54),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Editor
                      const Expanded(
                        child: CodeEditorWidget(),
                      ),
                    ],
                  ),

                  // Bottom Sheet for Output
                  const OutputSheet(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
