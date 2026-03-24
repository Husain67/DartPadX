import re

with open("dart_mini_ide/lib/screens/settings_screen.dart", "r") as f:
    content = f.read()

content = content.replace(r"\${", "${")
content = content.replace(r"\$e", "$e")

with open("dart_mini_ide/lib/screens/settings_screen.dart", "w") as f:
    f.write(content)
