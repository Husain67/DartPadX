import re

with open('pubspec.yaml', 'r') as f:
    content = f.read()

deps = """
  flutter_code_editor: ^0.2.0
  highlight: ^0.7.0
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
"""

content = re.sub(r'(dependencies:\n  flutter:\n    sdk: flutter)', r'\1\n' + deps, content)

with open('pubspec.yaml', 'w') as f:
    f.write(content)
