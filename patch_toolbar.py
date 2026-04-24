with open('dart_mini_ide/lib/ui/toolbar.dart', 'r') as f:
    content = f.read()

content = content.replace("import 'settings_screen.dart';", "import 'settings_screen.dart';\nimport 'examples_screen.dart';")
content = content.replace("          _ToolbarButton(\n            icon: Icons.add,", "          _ToolbarButton(\n            icon: Icons.lightbulb_outline,\n            label: 'Examples',\n            onTap: () {\n              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamplesGallery()));\n            },\n          ),\n          _ToolbarButton(\n            icon: Icons.add,")

with open('dart_mini_ide/lib/ui/toolbar.dart', 'w') as f:
    f.write(content)
