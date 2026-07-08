import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/compiler_provider.dart';
import '../../providers/editor_provider.dart';
import '../../providers/settings_provider.dart';
import '../toolbar/toolbar_widget.dart';
import 'code_editor_widget.dart';
import 'output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _sheetController;

  void _runCode() {
    final editorState = ref.read(editorProvider);
    final settingsState = ref.read(settingsProvider);
    final compilerNotifier = ref.read(compilerProvider.notifier);

    final activeFile = editorState.activeFile;
    if (activeFile == null || activeFile.content.isEmpty) return;

    compilerNotifier.runCode(activeFile.content, settingsState.activePreset);

    if (_sheetController == null) {
      _sheetController = _scaffoldKey.currentState?.showBottomSheet(
        (context) => const OutputSheet(),
        backgroundColor: Colors.transparent,
        enableDrag: true,
      );
      _sheetController?.closed.then((_) {
        _sheetController = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'DartMini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFACC15)),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Color(0xFFFACC15),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: compilerState.isRunning ? null : _runCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              icon: compilerState.isRunning
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.play_arrow, size: 20),
              label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
          ),
        ),
        child: const Column(
          children: [
            ToolbarWidget(),
            Expanded(child: CodeEditorWidget()),
          ],
        ),
      ),
    );
  }
}
