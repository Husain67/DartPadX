import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import 'dart:async';

import '../providers/file_provider.dart';
import '../providers/compiler_provider.dart';
import '../services/compiler_service.dart';
import 'theme.dart';
import 'widgets/toolbar_view.dart';
import 'widgets/output_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late CodeController _codeController;
  Timer? _debounce;
  bool _isLoading = false;
  ExecutionResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );
    _codeController.addListener(_onCodeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCodeController();
    });
  }

  void _onCodeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);
    });
  }

  void _syncCodeController() {
    final state = ref.read(fileProvider);
    final activeFile = state.files.firstWhere(
      (f) => f.id == state.activeFileId,
      orElse: () => state.files.first,
    );

    if (_codeController.text != activeFile.content) {
      _codeController.text = activeFile.content;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    // ensure saved before run
    ref.read(fileProvider.notifier).updateActiveFileContent(_codeController.text);

    final compilerState = ref.read(compilerProvider);
    final preset = compilerState.presets.firstWhere(
      (p) => p.id == compilerState.activePresetId,
      orElse: () => compilerState.presets.first,
    );

    final result = await CompilerService.runCode(
      code: _codeController.text,
      useOneCompiler: compilerState.useOneCompiler,
      preset: preset,
    );

    setState(() {
      _isLoading = false;
      _lastResult = result;
    });

    // Show bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => OutputSheet(result: _lastResult!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileState>(fileProvider, (previous, next) {
      if (previous?.activeFileId != next.activeFileId) {
        final activeFile = next.files.firstWhere((f) => f.id == next.activeFileId);
        _codeController.text = activeFile.content;
      }
    });

    final fileState = ref.watch(fileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            child: Center(
              child: InkWell(
                onTap: _isLoading ? null : _runCode,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
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
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          ToolbarView(codeController: _codeController),
          SizedBox(
            height: 40,
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
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
                        if (fileState.files.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => ref.read(fileProvider.notifier).deleteFile(file.id),
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
          Expanded(
            child: Container(
              color: const Color(0xFF2B2B2B), // standard editor background match Darcula
              child: SingleChildScrollView(
                child: CodeTheme(
                  data: CodeThemeData(styles: darculaTheme),
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    gutterStyle: const GutterStyle(
                      textStyle: TextStyle(color: Colors.white54, height: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
