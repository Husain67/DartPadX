import os
import re

def fix_string_interpolation(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # The bash heredoc escaped $ variables in our dart files. Let's fix them.
    # E.g. \${preset.authValue} -> ${preset.authValue}
    # and \$base64Str -> $base64Str
    content = re.sub(r'\\\$', '$', content)

    with open(filepath, 'w') as f:
        f.write(content)

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            fix_string_interpolation(os.path.join(root, file))
