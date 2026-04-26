import os

path = 'lib/ui/main_screen.dart'
with open(path, 'r') as f:
    content = f.read()

# I used raw strings `\${directory.path}` in python but the dart file needs actual variable interpolation... wait.
# If python writes it directly via python string, NOT via bash heredoc `cat << 'EOF'`, then python string raw string r"..." means the output text has a literal backslash `\`.
# Let's fix that.
content = content.replace(r"'\${directory.path}/\${activeFile.name}'", "'${directory.path}/${activeFile.name}'")
content = content.replace(r'"Downloaded to \${file.path}"', '"Downloaded to ${file.path}"')

with open(path, 'w') as f:
    f.write(content)
