import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/code_editor_view.dart';
import '../widgets/output_bottom_sheet.dart';
import '../services/compiler_api.dart';
import '../providers/file_provider.dart';
import '../providers/preset_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isRunning = false;

  Future<void> _runCode() async {
    final activeFile = ref.read(fileProvider).activeFile;
    if (activeFile == null) return;

    final useDefault = ref.read(presetProvider).useDefault;
    final selectedPreset = ref.read(presetProvider).selectedPreset;

    setState(() {
      _isRunning = true;
    });

    // Show loading sheet
    showOutputSheet(context, ExecutionResult(stdout: '', stderr: '', error: '', executionTime: '', memory: ''), isLoading: true);

    try {
      final result = await CompilerApi.executeDart(
        activeFile.content,
        preset: useDefault ? null : selectedPreset,
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading
      showOutputSheet(context, result);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      showOutputSheet(context, ExecutionResult(stdout: '', stderr: '', error: e.toString(), executionTime: '0 ms', memory: 'N/A'));
    } finally {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
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
              padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runCode,
                icon: _isRunning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                label: Text(
                  _isRunning ? 'Running' : 'Run',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  disabledBackgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),
        body: const Column(
          children: [
            EditorToolbar(),
            Expanded(child: CodeEditorView()),
          ],
        ),
      ),
    );
  }
}
