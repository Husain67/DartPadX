import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/toolbar.dart';
import '../widgets/file_tabs.dart';
import '../widgets/output_sheet.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late CodeController _codeController;
  String? _lastActiveId;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
    );

    _codeController.addListener(() {
      final activeId = ref.read(currentFileIdProvider);
      if (activeId != null && activeId == _lastActiveId) {
        ref.read(fileProvider.notifier).updateFileContent(activeId, _codeController.text);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final files = ref.read(fileProvider);
      if (files.isNotEmpty) {
        ref.read(currentFileIdProvider.notifier).state = files.first.id;
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(currentFileIdProvider, (previous, next) {
      if (next != null) {
        final files = ref.read(fileProvider);
        final file = files.firstWhere((f) => f.id == next, orElse: () => files.first);
        if (_codeController.text != file.content || next != _lastActiveId) {
          _lastActiveId = next;
          _codeController.text = file.content;
        }
      }
    });

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
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: Consumer(
              builder: (context, ref, child) {
                final isRunning = ref.watch(executionProvider).isRunning;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: isRunning
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          ref.read(executionProvider.notifier).runCode(_codeController.text);
                        },
                  child: isRunning
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Row(
                          children: [
                            Icon(Icons.play_arrow, size: 18),
                            SizedBox(width: 4),
                            Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  EditorToolbar(textController: _codeController),
                  const FileTabs(),
                  Expanded(
                    child: CodeTheme(
                      data: CodeThemeData(styles: darculaTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeController,
                          textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          gutterStyle: const GutterStyle(
                            textStyle: TextStyle(color: Colors.white38, fontSize: 14, fontFamily: 'monospace'),
                            showLineNumbers: true,
                            showErrors: true,
                            margin: 8.0,
                          ),
                          expands: false,
                          wrap: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _buildDraggableBottomSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return const OutputSheet();
      },
    );
  }
}
