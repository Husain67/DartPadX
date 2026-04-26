import os

path = 'lib/ui/main_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix Import icon and Add Download button, and Format Code button
# Import uses Icons.download right now. Let's change Import to Icons.file_download or Icons.upload_file
content = content.replace("icon: Icons.download,\n            label: 'Import',", "icon: Icons.file_upload,\n            label: 'Import',")

# Insert Download, Format
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

# Find where to insert them
import_btn_index = content.find("label: 'Copy',")
if import_btn_index != -1:
    # Insert before Copy
    content = content[:import_btn_index] + "\n" + "          " + content[import_btn_index:]

# Actually let's just use string replace at a safe anchor
anchor = "          _ToolbarBtn(\n            icon: Icons.copy,\n            label: 'Copy',"
if anchor in content:
    content = content.replace(anchor, download_format_code + anchor)

# Wait, `DartFormatter` and `getApplicationDocumentsDirectory` need imports
imports = """
import 'package:dart_style/dart_style.dart';
import 'package:path_provider/path_provider.dart';
"""

if "import 'package:dart_style/dart_style.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", imports + "import 'package:flutter/material.dart';")

with open(path, 'w') as f:
    f.write(content)
