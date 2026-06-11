import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';
import '../theme/app_theme.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import 'package:flutter/services.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'settings_screen.dart';
// Note: Some imports like copy, paste logic will be mapped later. Settings screen import later.

// ignore_for_file: prefer_const_constructors

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  bool _isInit = false;
  String? _lastActiveId;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(() {
      if (_isInit) {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      }
    });

    _stdinController.addListener(() {
      ref.read(executionProvider.notifier).setStdin(_stdinController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCodeController();
      setState(() {
        _isInit = true;
      });
    });
  }

  void _syncCodeController() {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile != null && activeFile.id != _lastActiveId) {
      _lastActiveId = activeFile.id;
      final currentText = activeFile.content;
      _codeController.text = currentText;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-sync if the active tab changed via Riverpod
    ref.listen(fileProvider.select((s) => s.activeFileId), (prev, next) {
      if (_isInit) {
        _syncCodeController();
      }
    });

    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

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
                color: AppTheme.primaryYellow,
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
            child: ElevatedButton.icon(
              onPressed: execState.isRunning
                  ? null
                  : () {
                      ref.read(executionProvider.notifier).executeCode(_codeController.text);
                      _showOutputSheet(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: execState.isRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.play_arrow, size: 20),
              label: Text(execState.isRunning ? 'Running...' : 'Run', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            // Toolbar
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildToolbarButton(Icons.add, 'New File', () {
                    ref.read(fileProvider.notifier).newFile();
                  }),
                  _buildToolbarButton(Icons.download, 'Import .dart', () {
                     ref.read(fileProvider.notifier).importFile();
                  }),
                  _buildToolbarButton(Icons.copy, 'Copy code', () {
                     Clipboard.setData(ClipboardData(text: _codeController.text));
                     Fluttertoast.showToast(msg: "Copied to clipboard", backgroundColor: AppTheme.surfaceColor, textColor: Colors.white);
                  }),
                  _buildToolbarButton(Icons.paste, 'Paste', () async {
                     final data = await Clipboard.getData(Clipboard.kTextPlain);
                     if (data != null && data.text != null) {
                       final text = data.text!;
                       final selection = _codeController.selection;
                       if (selection.isValid && selection.baseOffset <= _codeController.text.length) {
                         final newText = _codeController.text.replaceRange(selection.start, selection.end, text);
                         _codeController.value = TextEditingValue(
                           text: newText,
                           selection: TextSelection.collapsed(offset: selection.start + text.length),
                         );
                       } else {
                         _codeController.text += text;
                       }
                     }
                  }),
                  _buildToolbarButton(Icons.download_rounded, 'Download .dart', () {
                     ref.read(fileProvider.notifier).exportFile();
                  }),
                  _buildToolbarButton(Icons.share, 'Share', () {
                     ref.read(fileProvider.notifier).exportFile();
                  }),
                  _buildToolbarButton(Icons.format_align_left, 'Format', () {
                     try {
                       final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                       final formatted = formatter.format(_codeController.text);
                       _codeController.text = formatted;
                     } catch (e) {
                       Fluttertoast.showToast(msg: "Syntax error, cannot format", backgroundColor: Colors.redAccent, textColor: Colors.white);
                     }
                  }),
                  _buildToolbarButton(Icons.delete, 'Delete', () {
                     showDialog(
                       context: context,
                       builder: (ctx) => AlertDialog(
                         title: Text('Delete File', style: TextStyle(color: Colors.white)),
                         content: Text('Delete this file? This cannot be undone.', style: TextStyle(color: Colors.white70)),
                         backgroundColor: AppTheme.surfaceColor,
                         actions: [
                           TextButton(
                             onPressed: () => Navigator.pop(ctx),
                             child: Text('Cancel', style: TextStyle(color: Colors.white54)),
                           ),
                           TextButton(
                             onPressed: () {
                               final activeFileId = ref.read(fileProvider).activeFileId;
                               if (activeFileId != null) {
                                 ref.read(fileProvider.notifier).deleteFile(activeFileId);
                               }
                               Navigator.pop(ctx);
                               Fluttertoast.showToast(msg: "File deleted", backgroundColor: AppTheme.surfaceColor, textColor: Colors.white);
                             },
                             child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                           ),
                         ],
                       ),
                     );
                  }),
                  _buildToolbarButton(Icons.settings, 'Settings', () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),
            // File Tabs
            Container(
              height: 40,
              color: AppTheme.surfaceColor,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: fileState.files.map((file) {
                  final isActive = file.id == fileState.activeFileId;
                  return _buildTab(
                    file.name,
                    isActive,
                    () => ref.read(fileProvider.notifier).switchTab(file.id),
                    () => ref.read(fileProvider.notifier).closeTab(file.id),
                  );
                }).toList(),
              ),
            ),
            // Editor Area
            Expanded(
              child: CodeTheme(
                data: CodeThemeData(styles: monokaiSublimeTheme),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: GutterStyle(
                      textStyle: const TextStyle(color: Colors.white54, height: 1.5),
                      showLineNumbers: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: AppTheme.toolbarButtonStyle,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _buildTab(String title, bool isActive, VoidCallback onTap, VoidCallback onClose) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.backgroundStart : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryYellow : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close,
                size: 16,
                color: isActive ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOutputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final execState = ref.watch(executionProvider);
                  return Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Output', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
                                  tooltip: 'Clear Output',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      // Stdin
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          controller: _stdinController,
                          decoration: const InputDecoration(
                            labelText: 'Standard Input (stdin)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      // Output Console
                      Expanded(
                        child: ListView(
                          controller: controller,
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (execState.isRunning)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              if (execState.stdout.isNotEmpty)
                                Text(
                                  execState.stdout,
                                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                                ),
                              if (execState.stderr.isNotEmpty)
                                Text(
                                  execState.stderr,
                                  style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                                ),
                              if (execState.stdout.isEmpty && execState.stderr.isEmpty)
                                const Text('No output', style: TextStyle(color: Colors.white54)),
                              const SizedBox(height: 16),
                              if (execState.executionTime.isNotEmpty)
                                Text('Execution Time: ${execState.executionTime}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              if (execState.memory.isNotEmpty)
                                Text('Memory: ${execState.memory}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      ref.read(executionProvider.notifier).setOutputVisible(false);
    });
  }
}
