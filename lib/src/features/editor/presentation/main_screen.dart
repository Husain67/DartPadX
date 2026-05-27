import 'package:flutter/material.dart';
import 'package:dart_style/dart_style.dart';

import 'package:dartmini_ide/src/features/editor/presentation/examples_gallery.dart';

import 'package:dartmini_ide/src/features/settings/presentation/settings_screen.dart';

import 'package:dartmini_ide/src/features/editor/presentation/output_sheet.dart';
import 'package:dartmini_ide/src/features/editor/utils/file_actions.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartmini_ide/src/core/theme/app_theme.dart';
import 'package:dartmini_ide/src/core/constants/ui_constants.dart';
import 'package:dartmini_ide/src/features/editor/providers/file_provider.dart';
import 'package:dartmini_ide/src/features/editor/providers/execution_provider.dart';
import 'package:dartmini_ide/src/features/editor/presentation/code_editor_widget.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('DartMini'),
            SizedBox(width: 8),
            BadgePill(text: 'beta'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _buildRunButton(),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: Stack(
                children: [
                  // Placeholder for CodeEditorWidget
                  const CodeEditorWidget(),
                  // Placeholder for OutputSheet
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: OutputSheet(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    final executionState = ref.watch(executionProvider);

    return ElevatedButton(
      onPressed: executionState.isRunning ? null : () {
        final activeFile = ref.read(fileProvider).activeFile;
        if (activeFile != null) {
           ref.read(executionProvider.notifier).runCode(activeFile.content);
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: executionState.isRunning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, size: 20),
                SizedBox(width: 4),
                Text('Run', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: UIConstants.toolbarPadding,
      child: Row(
        children: [

          ToolbarButton(
            icon: Icons.add,
            label: 'New File',
            onPressed: () => ref.read(fileProvider.notifier).createFile(),
          ),
          ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Import .dart',
            onPressed: () async {
               final data = await FileActions.importFile();
               if (data != null) {
                 ref.read(fileProvider.notifier).importFile(data['name']!, data['content']!);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.copy,
            label: 'Copy code',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.copyToClipboard(activeFile.content);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.paste,
            label: 'Paste',
            onPressed: () async {
               final text = await FileActions.pasteFromClipboard();
               if (text != null) {
                 ref.read(fileProvider.notifier).updateActiveFileContent(text);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.file_download,
            label: 'Download .dart',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.downloadFile(activeFile);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.share,
            label: 'Share',
            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 FileActions.shareFile(activeFile);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.delete,
            label: 'Delete',
            onPressed: () async {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile == null) return;

               final confirm = await showDialog<bool>(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Delete File?'),
                   content: const Text('This cannot be undone.'),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, false),
                       child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                     ),
                     TextButton(
                       onPressed: () => Navigator.pop(ctx, true),
                       child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                     ),
                   ],
                 )
               );

               if (confirm == true && mounted) {
                 ref.read(fileProvider.notifier).deleteActiveFile();
               }
            },
          ),


          ToolbarButton(
            icon: Icons.clear_all,
            label: 'Clear Output',
            onPressed: () => ref.read(executionProvider.notifier).clearOutput(),
          ),
          ToolbarButton(
            icon: Icons.collections,
            label: 'Examples',
            onPressed: () async {
               final result = await showDialog<Map<String, String>>(
                 context: context,
                 builder: (context) => const ExamplesGallery(),
               );
               if (result != null && mounted) {
                 ref.read(fileProvider.notifier).importFile('${result['name']!}.dart', result['code']!);
               }
            },
          ),
          ToolbarButton(
            icon: Icons.format_align_left,
            label: 'Format',

            onPressed: () {
               final activeFile = ref.read(fileProvider).activeFile;
               if (activeFile != null) {
                 try {
                   final formatter = DartFormatter();
                   final formatted = formatter.format(activeFile.content);
                   ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                   // force a state update so code_editor_widget resyncs
                   ref.read(fileProvider.notifier).setActiveFile(activeFile.id);
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Format error: $e')));
                 }
               }
            },

          ),
          ToolbarButton(
            icon: Icons.settings,
            label: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
