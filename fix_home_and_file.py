import re

# Fix unnecessary string escapes in file_provider
with open("lib/providers/file_provider.dart", "r") as f:
    file_content = f.read()

file_content = file_content.replace("\\'", "'")
file_content = file_content.replace("\\$", "$")

with open("lib/providers/file_provider.dart", "w") as f:
    f.write(file_content)

# Implement DartFormatter in home_screen
with open("lib/ui/screens/home_screen.dart", "r") as f:
    home_content = f.read()

home_content = home_content.replace("import 'dart:async';", "import 'dart:async';\nimport 'package:dart_style/dart_style.dart';")

old_format_btn = """                  ToolbarButton(
                    icon: Icons.format_align_left,
                    label: 'Format Code',
                    onTap: () {
                      // Basic formatting simulation (or use dart_style if added, but for now we just show a toast)
                      Fluttertoast.showToast(msg: "Formatting not supported in beta");
                    },
                  ),"""

new_format_btn = """                  ToolbarButton(
                    icon: Icons.format_align_left,
                    label: 'Format Code',
                    onTap: () {
                      if (_codeController != null) {
                        try {
                          final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
                          final formatted = formatter.format(_codeController!.text);
                          _codeController!.text = formatted;
                          Fluttertoast.showToast(msg: "Code formatted");
                        } catch (e) {
                          Fluttertoast.showToast(msg: "Syntax error: Cannot format");
                        }
                      }
                    },
                  ),"""

home_content = home_content.replace(old_format_btn, new_format_btn)

with open("lib/ui/screens/home_screen.dart", "w") as f:
    f.write(home_content)
