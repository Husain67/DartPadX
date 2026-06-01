import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/file_provider.dart';
import '../providers/execution_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/output_sheet.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final execState = ref.watch(executionProvider);

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
              child: const Text('beta', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: execState.isExecuting ? null : () {
                FocusScope.of(context).unfocus();
                ref.read(executionProvider.notifier).executeCode();
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: execState.isExecuting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Row(
                    children: [
                      Icon(Icons.play_arrow, color: Colors.black),
                      SizedBox(width: 4),
                      Text('Run', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: AppTheme.backgroundGradient,
          child: Column(
            children: [
              // Tabs
              Container(
                height: 40,
                color: Colors.black54,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: fileState.files.length,
                  itemBuilder: (ctx, i) {
                    final f = fileState.files[i];
                    final isActive = f.id == fileState.activeFileId;
                    return InkWell(
                      onTap: () => ref.read(fileProvider.notifier).setActiveFile(f.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                              width: 3,
                            )
                          ),
                          color: isActive ? Colors.white10 : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f.name,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white54,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                if (isActive) {
                                  ref.read(fileProvider.notifier).deleteActiveFile();
                                } else {
                                  // Not requested to close inactive tabs specifically, but we could
                                }
                              },
                              child: Icon(Icons.close, size: 16, color: isActive ? Colors.white : Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const ToolbarWidget(),

              const Expanded(
                child: EditorWidget(),
              ),

              if (execState.showOutput)
                Expanded(
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.5,
                    minChildSize: 0.2,
                    maxChildSize: 1.0,
                    builder: (BuildContext context, ScrollController scrollController) {
                      return const OutputSheet();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
