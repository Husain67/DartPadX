import re

with open('pubspec.yaml', 'r') as f:
    content = f.read()

if 'hive_generator' not in content:
    content = content.replace('dev_dependencies:', 'dev_dependencies:\n  hive_generator: ^2.0.1\n  build_runner: ^2.4.11')
    with open('pubspec.yaml', 'w') as f:
        f.write(content)
