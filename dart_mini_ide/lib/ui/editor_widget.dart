import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';
import '../providers/file_provider.dart';

class EditorWidget extends ConsumerStatefulWidget {
  const EditorWidget({super.key});

  @override
  ConsumerState<EditorWidget> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends ConsumerState<EditorWidget> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '',
      language: dart,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active file content changes from provider (e.g. if updated elsewhere)
    // and listen to active index changes to switch file.

    ref.listen(fileProvider.select((s) => s.activeIndex), (previous, next) {
      if (previous != next) {
        final file = ref.read(fileProvider).files[next];
        if (_controller.text != file.content) {
          _controller.text = file.content;
        }
      }
    });

    final activeFile = ref.watch(fileProvider.select((s) => s.activeFile));
    if (activeFile != null && _controller.text.isEmpty && activeFile.content.isNotEmpty) {
       _controller.text = activeFile.content;
    }

    // Basic Monokai-like theme
    const theme = {
      'root': TextStyle(backgroundColor: Color(0xFF1E1E1E), color: Color(0xFFF8F8F2)),
      'keyword': TextStyle(color: Color(0xFFF92672), fontWeight: FontWeight.bold),
      'selector-tag': TextStyle(color: Color(0xFFF92672), fontWeight: FontWeight.bold),
      'literal': TextStyle(color: Color(0xFFAE81FF)),
      'section': TextStyle(color: Color(0xFFA6E22E), fontWeight: FontWeight.bold),
      'link': TextStyle(color: Color(0xFFFD971F)),
      'subst': TextStyle(color: Color(0xFFF8F8F2)),
      'string': TextStyle(color: Color(0xFFE6DB74)),
      'title': TextStyle(color: Color(0xFFA6E22E), fontWeight: FontWeight.bold),
      'name': TextStyle(color: Color(0xFFA6E22E), fontWeight: FontWeight.bold),
      'type': TextStyle(color: Color(0xFFA6E22E), fontWeight: FontWeight.bold),
      'attribute': TextStyle(color: Color(0xFFA6E22E)),
      'symbol': TextStyle(color: Color(0xFF66D9EF)),
      'bullet': TextStyle(color: Color(0xFFF92672)),
      'built_in': TextStyle(color: Color(0xFF66D9EF)),
      'addition': TextStyle(color: Color(0xFFA6E22E)),
      'variable': TextStyle(color: Color(0xFFF8F8F2)),
      'template-tag': TextStyle(color: Color(0xFFF92672)),
      'template-variable': TextStyle(color: Color(0xFFF8F8F2)),
      'comment': TextStyle(color: Color(0xFF75715E), fontStyle: FontStyle.italic),
      'quote': TextStyle(color: Color(0xFF75715E), fontStyle: FontStyle.italic),
      'deletion': TextStyle(color: Color(0xFF75715E)),
      'meta': TextStyle(color: Color(0xFF75715E)),
      'doctag': TextStyle(color: Color(0xFF75715E), fontWeight: FontWeight.bold),
    };

    return CodeTheme(
      data: CodeThemeData(styles: theme),
      child: CodeField(
        controller: _controller,
        textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        onChanged: (value) {
           // Update provider
           // We need to avoid rebuilding this widget if we trigger a state change that we watch.
           // However, we are watching activeFile.content implicitly?
           // No, we select activeFile. But we don't use activeFile.content in build except for init.
           // So it should be fine.
           ref.read(fileProvider.notifier).updateFileContent(value);
        },
        expands: true,
        gutterStyle: const GutterStyle(
           showLineNumbers: true,
           showErrors: false,
           margin: 5,
           textStyle: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
