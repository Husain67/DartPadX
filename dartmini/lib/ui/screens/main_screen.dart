import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart';
import 'dart:convert';
import 'dart:async';

import '../../app_theme.dart';
import '../widgets/toolbar_button.dart';
import '../widgets/file_tabs.dart';
import '../widgets/output_sheet.dart';
import '../../providers/file_provider.dart';
import '../../providers/execution_provider.dart';
import 'settings_screen.dart';
import 'package:dart_style/dart_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final FocusNode _editorFocusNode = FocusNode();
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncEditorWithState();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    // Debounce auto-save
    _autoSaveTimer?.cancel();
    if (!const bool.hasEnvironment('FLUTTER_TEST')) {
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
      });
    } else {
       // In test mode, save immediately to prevent timer issues
       ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  void _syncEditorWithState() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && _codeController.text != activeFile.content) {
      _codeController.text = activeFile.content;
    }
  }

  void _forceSaveCurrent() {
    // Force immediate save before changing tabs
    _autoSaveTimer?.cancel();
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
  }

  // --- Toolbar Handlers ---
  void _handleNewFile() {
    _showTextInputDialog(
      title: 'New File',
      hint: 'filename.dart',
      onConfirm: (name) {
        if (!name.endsWith('.dart')) name += '.dart';
        ref.read(fileProvider.notifier).addFile(name);
      },
    );
  }

  void _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      ref.read(fileProvider.notifier).addFile(result.files.single.name, content);
      Fluttertoast.showToast(msg: "File imported", backgroundColor: Colors.green);
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    Fluttertoast.showToast(msg: "Code copied to clipboard!", backgroundColor: Colors.green);
  }

  void _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      final currentPos = _codeController.selection.baseOffset;
      if (currentPos >= 0) {
        final newText = _codeController.text.replaceRange(
          _codeController.selection.start,
          _codeController.selection.end,
          data!.text!,
        );
        _codeController.text = newText;
        _codeController.selection = TextSelection.collapsed(offset: currentPos + data.text!.length);
      } else {
         _codeController.text += data!.text!;
      }
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    }
  }

  void _handleFormat() {
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(_codeController.text);
      _codeController.text = formatted;
      ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
      Fluttertoast.showToast(msg: "Code formatted", backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: "Syntax error: Cannot format", backgroundColor: Colors.red);
    }
  }

  void _handleDownload() async {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${activeFile.name}';
      final file = File(path);
      await file.writeAsString(_codeController.text);
      Fluttertoast.showToast(msg: "Downloaded to $path", backgroundColor: Colors.green, toastLength: Toast.LENGTH_LONG);
    }
  }

  void _handleShare() {
     final bytes = utf8.encode(_codeController.text);
     final String base64Str = base64.encode(bytes);
     // ignore: deprecated_member_use
     Share.share('Check out my Dart code snippet:\ndartmini://code?data=$base64Str');
  }

  void _handleDelete() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete File'),
            content: Text('Delete "\${activeFile.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  ref.read(fileProvider.notifier).deleteFile(activeFile.id);
                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: "File deleted", backgroundColor: Colors.green);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }
  }

  void _handleSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _runCode() {
    // Force save before running
    _forceSaveCurrent();

    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      final stdin = ref.read(stdinProvider);
      ref.read(executionProvider.notifier).executeCode(activeFile.content, stdin);
    }
  }

  void _showTextInputDialog({required String title, required String hint, required Function(String) onConfirm}) {
    String input = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
            onChanged: (val) => input = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (input.isNotEmpty) {
                  onConfirm(input);
                  Navigator.pop(context);
                }
              },
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryYellow)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);

    // Listen for file changes (e.g. user switching tabs)
    ref.listen(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        // We switched tabs, push current state of controller to previous file
        if (previous?.activeFileId != null) {
             _autoSaveTimer?.cancel();
             // Note: We can't easily push the text to the old file here because
             // we don't have its old content, we already overwrote _codeController
             // in _syncEditorWithState or we are about to.
             // That's why we call _forceSaveCurrent() manually on tab taps in file_tabs.dart
             // if we had access to it. For this version, auto-save debounce handles it mostly,
             // but we sync the new file right now.
        }
        _syncEditorWithState();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton.icon(
              onPressed: executionState.isExecuting ? null : _runCode,
              icon: executionState.isExecuting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Run', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Toolbar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    ToolbarButton(label: 'New', icon: '📄', onTap: _handleNewFile),
                    ToolbarButton(label: 'Import', icon: '📥', onTap: _handleImport),
                    ToolbarButton(label: 'Copy', icon: '📋', onTap: _handleCopy),
                    ToolbarButton(label: 'Paste', icon: '📝', onTap: _handlePaste),
                    ToolbarButton(label: 'Format', icon: '✨', onTap: _handleFormat),
                    ToolbarButton(label: 'Download', icon: '⬇️', onTap: _handleDownload),
                    ToolbarButton(label: 'Share', icon: '🔗', onTap: _handleShare),
                    ToolbarButton(label: 'Delete', icon: '🗑️', onTap: _handleDelete),
                    ToolbarButton(label: 'Settings', icon: '⚙️', onTap: _handleSettings),
                  ],
                ),
              ),
              // File Tabs
              const FileTabs(),
              // Stdin Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.backgroundDeepBlack,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Standard Input (stdin)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 1,
                  onChanged: (val) {
                    ref.read(stdinProvider.notifier).state = val;
                  },
                ),
              ),
              // Editor Space
              Expanded(
                child: Container(
                  color: AppTheme.backgroundDeepBlack,
                  child: CodeTheme(
                    data: CodeThemeData(styles: atomOneDarkTheme),
                    child: SingleChildScrollView(
                      child: FocusableActionDetector(
                        shortcuts: {
                          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): const SaveIntent(),
                          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyS): const SaveIntent(),
                        },
                        actions: {
                          SaveIntent: CallbackAction<SaveIntent>(
                            onInvoke: (intent) {
                              _forceSaveCurrent();
                              Fluttertoast.showToast(msg: "Saved!", backgroundColor: Colors.green);
                              return null;
                            },
                          ),
                        },
                        child: CodeField(
                          controller: _codeController,
                          focusNode: _editorFocusNode,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(height: 1.5, color: Colors.grey),
                            width: 40,
                            margin: 8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Output Sheet
          const OutputSheet(),
        ],
      ),
    );
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}
