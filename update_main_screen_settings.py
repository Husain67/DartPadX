import re

with open('lib/src/features/editor/presentation/main_screen.dart', 'r') as f:
    content = f.read()

imports = "import 'package:dartmini_ide/src/features/settings/presentation/settings_screen.dart';\n"
content = re.sub(r"(import 'package:flutter/material\.dart';)", r"\1\n" + imports, content)

content = content.replace(
    "ToolbarButton(\n            icon: Icons.settings,\n            label: 'Settings',\n            onPressed: () {},\n          ),",
    "ToolbarButton(\n            icon: Icons.settings,\n            label: 'Settings',\n            onPressed: () {\n              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));\n            },\n          ),"
)

with open('lib/src/features/editor/presentation/main_screen.dart', 'w') as f:
    f.write(content)
