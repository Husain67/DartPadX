import os

path = 'lib/ui/main_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# I messed up injecting the Download code because the search string wasn't exactly right.
# Let's just find `_ToolbarBtn(`
anchor = """          _ToolbarBtn(
            icon: Icons.copy,"""

download_format_code = """          _ToolbarBtn(
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

if anchor in content:
    content = content.replace(anchor, download_format_code + anchor)

# Also fix the download path variable interpolation
content = content.replace("'${directory.path}/${activeFile.name}'", r"'\${directory.path}/\${activeFile.name}'")
content = content.replace('"Downloaded to ${file.path}"', r'"Downloaded to \${file.path}"')

with open(path, 'w') as f:
    f.write(content)
