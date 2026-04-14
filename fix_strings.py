import sys

def fix_settings():
    with open('dart_mini_ide/lib/ui/screens/settings_screen.dart', 'r') as f:
        content = f.read()

    # Fix the tempDir issue and string interpolation
    content = content.replace("final path = '\\${tempDir.path}/dart_mini_ide_presets.json';", "final path = '${tempDir.path}/dart_mini_ide_presets.json';")
    content = content.replace("Fluttertoast.showToast(msg: 'Loaded \\${ex['title']}');", 'Fluttertoast.showToast(msg: "Loaded ${ex[\'title\']}");')
    content = content.replace("\"\\${ex['title']!.replaceAll(' ', '_')}.dart\",", "\"...${ex['title']!.replaceAll(' ', '_')}.dart\",".replace("...", ""))

    with open('dart_mini_ide/lib/ui/screens/settings_screen.dart', 'w') as f:
        f.write(content)

def fix_toolbar():
    with open('dart_mini_ide/lib/ui/widgets/toolbar_widget.dart', 'r') as f:
        content = f.read()

    content = content.replace("final path = '\\${tempDir.path}/\\${activeFile.name}';", "final path = '${tempDir.path}/${activeFile.name}';")
    content = content.replace("Share.share('Check out my Dart code!\\\\n\\\\nBase64:\\\\n\\$base64Code');", "Share.share('Check out my Dart code!\\n\\nBase64:\\n$base64Code');")

    with open('dart_mini_ide/lib/ui/widgets/toolbar_widget.dart', 'w') as f:
        f.write(content)

fix_settings()
fix_toolbar()
