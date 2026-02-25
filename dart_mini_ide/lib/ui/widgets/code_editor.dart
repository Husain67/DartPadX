import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/code_file.dart';
import '../../providers/file_provider.dart';
import '../theme/app_theme.dart';

// Provider to expose the active controller to Toolbar
final activeEditorControllerProvider = StateProvider<CodeController?>((ref) => null);

class CodeEditorWidget extends ConsumerStatefulWidget {
  const CodeEditorWidget({super.key});

  @override
  ConsumerState<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends ConsumerState<CodeEditorWidget> {
  CodeController? _controller;
  Timer? _autoSaveTimer;
  String? _currentFileId;

  @override
  void initState() {
    super.initState();
    // Initial setup if provider already has data
    final file = ref.read(fileProvider);
    if (file != null) {
      _initController(file.content);
      _currentFileId = file.id;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );

    _controller!.addListener(_onCodeChanged);

    // Update the provider so other widgets can access the controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeEditorControllerProvider.notifier).state = _controller;
      }
    });
  }

  void _onCodeChanged() {
    // Debounce save
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_controller != null && _currentFileId != null) {
        // We update content without rebuilding the whole widget tree unnecessarily
        // But we need to make sure we don't trigger a rebuild that re-inits controller!
        ref.read(fileProvider.notifier).updateContent(_controller!.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for file changes
    ref.listen<CodeFile?>(fileProvider, (previous, next) {
      if (next == null) {
        if (_controller != null) {
          _controller!.dispose();
          _controller = null;
          ref.read(activeEditorControllerProvider.notifier).state = null;
          setState(() {});
        }
      } else if (previous?.id != next.id) {
        // Different file selected
        _currentFileId = next.id;
        _initController(next.content);
        setState(() {});
      }
    });

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent));
    }

    return CodeTheme(
      data: CodeThemeData(styles: vs2015Theme),
      child: CodeField(
        controller: _controller!,
        textStyle: GoogleFonts.jetBrainsMono(fontSize: 14),
        gutterStyle: GutterStyle(
          textStyle: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.grey),
          width: 50,
          margin: 0,
          background: AppTheme.darkBackgroundStart,
        ),
        background: AppTheme.darkBackgroundStart,
      ),
    );
  }
}
