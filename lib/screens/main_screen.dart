import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/preset_provider.dart';
import '../theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/output_sheet.dart';
import '../services/compiler_service.dart';
import 'dart:async';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late CodeController _codeController;
  final FocusNode _editorFocusNode = FocusNode();
  String? _currentActiveId;
  final TextEditingController _stdinController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    _stdinController.addListener(() {
        ref.read(stdinProvider.notifier).state = _stdinController.text;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncEditorWithState();
    });
  }

  void _onCodeChanged() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null && activeFile.content != _codeController.text) {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
          ref.read(fileProvider.notifier).updateFileContent(activeFile.id, _codeController.text);
      });
    }
  }

  void _syncEditorWithState() {
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile != null) {
      if (_currentActiveId != activeFile.id) {
        _forceSave();
        _currentActiveId = activeFile.id;
        if (_codeController.text != activeFile.content) {
          _codeController.text = activeFile.content;
        }
      } else {
        if (_codeController.text != activeFile.content) {
          var selection = _codeController.selection;
          _codeController.text = activeFile.content;

          if (selection.baseOffset > _codeController.text.length) {
             selection = TextSelection.collapsed(offset: _codeController.text.length);
          }
          _codeController.selection = selection;
        }
      }
    } else {
      _codeController.text = '';
      _currentActiveId = null;
    }
  }

  void _forceSave({String? specificId}) {
      final id = specificId ?? _currentActiveId;
      if (id != null) {
          ref.read(fileProvider.notifier).updateFileContent(id, _codeController.text);
      }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _editorFocusNode.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    _forceSave();
    final activeFile = ref.read(fileProvider.notifier).activeFile;
    if (activeFile == null) return;

    ref.read(executionProvider.notifier).setRunning(true);

    final presetState = ref.read(presetProvider);
    final compilerService = CompilerService();
    final stdin = ref.read(stdinProvider);

    try {
      if (presetState.useDefaultOneCompiler || presetState.activePresetId == null) {
        await compilerService.runCode(activeFile.content, stdin, ref);
      } else {
        final activePreset = presetState.presets.firstWhere((p) => p.id == presetState.activePresetId);
        await compilerService.runCustomCode(activeFile.content, stdin, activePreset, ref);
      }
    } catch (e) {
      ref.read(executionProvider.notifier).setOutput(
        stderr: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      _syncEditorWithState();
    });

    final fileState = ref.watch(fileProvider);
    final executionState = ref.watch(executionProvider);

    return Scaffold(
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
                  color: AppTheme.pureBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: executionState.isRunning ? null : _runCode,
              icon: executionState.isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.pureBlack)
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const EditorToolbar(),
              _buildTabs(fileState),
              Expanded(
                child: _buildEditor(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.darkGray,
                child: TextField(
                  controller: _stdinController,
                  decoration: const InputDecoration(
                    hintText: 'Standard Input (stdin)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 100), // Space for output sheet
            ],
          ),
          const OutputSheet(),
        ],
      ),
    );
  }

  Widget _buildTabs(FileState fileState) {
    return Container(
      height: 40,
      color: AppTheme.pureBlack,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fileState.files.length,
        itemBuilder: (context, index) {
          final file = fileState.files[index];
          final isActive = file.id == fileState.activeFileId;
          return GestureDetector(
            onTap: () {
                _forceSave();
                ref.read(fileProvider.notifier).setActiveFile(file.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.darkGray : AppTheme.pureBlack,
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
                      color: isActive ? AppTheme.primaryAccent : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref.read(fileProvider.notifier).deleteFile(file.id);
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.white70),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: CodeTheme(
            data: CodeThemeData(styles: draculaTheme),
            child: CodeField(
              controller: _codeController,
              focusNode: _editorFocusNode,
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        );
      }
    );
  }
}
