import os
import re

def fix_examples():
    path = 'lib/ui/examples_gallery.dart'
    with open(path, 'r') as f:
        content = f.read()

    # Remove `const` from `const ExamplesGallery({super.key});`
    content = content.replace("const ExamplesGallery({super.key});", "ExamplesGallery({super.key});")

    # Escape $ in string literals again because we unescaped everything but Dart actually requires variables to be escaped if we want literal $ inside a multiline string!
    # Wait, in ExamplesGallery, the text is literal code that users will copy to editor.
    # E.g. print('Hi, I am $name and I am $age years old.');
    # In dart, if you have `$name` in a string, it interpolates. So we must escape it like `\$name`!
    content = content.replace("$name", r"\$name").replace("$age", r"\$age")

    with open(path, 'w') as f:
        f.write(content)

def fix_unused_imports():
    path = 'lib/ui/main_screen.dart'
    with open(path, 'r') as f:
        content = f.read()

    # We added dart_style and path_provider but the reviewer said Download was missing, maybe I injected the Download button wrong?
    # Let's check if the Download button actually exists in main_screen.dart

    if "icon: Icons.format_align_left" not in content:
        # The injection failed!
        # Let's manually add it again using regex safely.
        anchor = "          _ToolbarBtn(\n            icon: Icons.copy,\n            label: 'Copy',"
        download_format_code = """
          _ToolbarBtn(
            icon: Icons.download,
            label: 'Download',
            onTap: () async {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/${activeFile.name}');
                await file.writeAsString(activeFile.content);
                Fluttertoast.showToast(msg: "Downloaded to ${file.path}");
              }
            },
          ),
          _ToolbarBtn(
            icon: Icons.format_align_left,
            label: 'Format',
            onTap: () {
              final activeFile = ref.read(fileProvider).activeFile;
              if (activeFile != null) {
                try {
                  final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                  final formatted = formatter.format(activeFile.content);
                  ref.read(fileProvider.notifier).updateActiveFileContent(formatted);
                  Fluttertoast.showToast(msg: "Code Formatted");
                } catch(e) {
                  Fluttertoast.showToast(msg: "Formatting error (Syntax)");
                }
              }
            },
          ),
"""
        content = content.replace(anchor, download_format_code + anchor)

    with open(path, 'w') as f:
        f.write(content)

fix_examples()
fix_unused_imports()
