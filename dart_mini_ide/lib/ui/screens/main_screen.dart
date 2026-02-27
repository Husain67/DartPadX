import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../logic/providers/execution_provider.dart';
import '../../logic/providers/files_provider.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/output_sheet_widget.dart';
import '../widgets/toolbar_widget.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final executionState = ref.watch(executionProvider);
    final filesState = ref.watch(filesProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent, // Uses container gradient
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Allow gradient to show, or solid black if preferred
        elevation: 0,
        title: Row(
          children: [
            const Text('DartMini', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'beta',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Run Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: executionState.isLoading
                    ? null
                    : () async {
                        final code = filesState.activeFile?.content;
                        if (code != null && code.isNotEmpty) {
                          // Trigger execution
                          await ref.read(executionProvider.notifier).execute(code);
                          // We don't need to manually show bottom sheet as it's always there but draggable
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No code to run')),
                          );
                        }
                      },
                icon: executionState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.play_arrow, color: Colors.black),
                label: Text(
                  executionState.isLoading ? 'Running...' : 'Run',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
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
                  // File Tabs
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filesState.files.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final file = filesState.files[index];
                        final isActive = file.id == filesState.activeFile?.id;
                        return GestureDetector(
                          onTap: () {
                            ref.read(filesProvider.notifier).setActiveFile(file);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.surfaceColor : Colors.transparent,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              border: isActive
                                  ? const Border(top: BorderSide(color: AppTheme.primaryAccent, width: 2))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  file.name,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Toolbar
                  const ToolbarWidget(),
                  const Divider(height: 1, color: Colors.white10),

                  // Editor
                  const Expanded(
                    child: CodeEditorWidget(),
                  ),

                  // Space for Bottom Sheet Handle visibility when collapsed
                  const SizedBox(height: 50),
                ],
              ),

              // Output Sheet
              const OutputSheetWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
