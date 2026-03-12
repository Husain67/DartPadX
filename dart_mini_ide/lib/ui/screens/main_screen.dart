import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/top_app_bar.dart';
import '../widgets/action_toolbar.dart';
import '../widgets/editor_tabs.dart';
import '../widgets/code_editor.dart';
import '../widgets/output_sheet.dart';
import '../../providers/execution_provider.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return Scaffold(
      appBar: const TopAppBar(),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const Column(
          children: [
            ActionToolbar(),
            EditorTabs(),
            Expanded(
              child: CodeEditorWidget(),
            ),
          ],
        ),
      ),
      bottomSheet: executionState.showOutput
          ? DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.1,
              maxChildSize: 0.8,
              expand: false,
              builder: (context, scrollController) {
                return const OutputSheet();
              },
            )
          : null,
    );
  }
}
