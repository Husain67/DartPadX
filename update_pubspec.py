import re

with open('pubspec.yaml', 'r') as f:
    content = f.read()

deps = """dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  flutter_code_editor: ^0.3.3
  flutter_highlight: ^0.7.0
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  http: ^1.2.2
  shared_preferences: ^2.3.0
  fluttertoast: ^8.2.8
  path_provider: ^2.1.4
  url_launcher: ^6.3.0
  share_plus: ^10.0.0
  file_picker: ^8.1.2
  flutter_markdown: ^0.7.4
  uuid: ^4.5.1
  dart_style: ^3.1.7"""

content = re.sub(r'dependencies:\n  flutter:\n    sdk: flutter\n\n  # The following adds the Cupertino Icons font to your application\.\n  # Use with the CupertinoIcons class for iOS style icons\.\n  cupertino_icons: \^1\.0\.8', deps, content, flags=re.MULTILINE)

with open('pubspec.yaml', 'w') as f:
    f.write(content)
